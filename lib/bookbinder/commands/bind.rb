require 'middleman-syntax'

require_relative '../archive_menu_configuration'
require_relative '../dita_section_gatherer_factory'
require_relative '../errors/cli_error'
require_relative '../preprocessing/copy_to_site_gen_dir'
require_relative '../streams/switchable_stdout_and_red_stderr'
require_relative '../values/output_locations'
require_relative '../values/section'
require_relative 'naming'

module Bookbinder
  module Commands
    class Bind
      include Commands::Naming

      DitaToHtmlLibraryFailure = Class.new(RuntimeError)

      def initialize(logger,
                     config_factory,
                     archive_menu_config,
                     version_control_system,
                     file_system_accessor,
                     static_site_generator,
                     sitemap_writer,
                     final_app_directory,
                     context_dir,
                     preprocessor,
                     cloner_factory,
                     dita_section_gatherer_factory,
                     section_repository_factory,
                     command_creator,
                     sheller,
                     directory_preparer)
        @logger = logger
        @config_factory = config_factory
        @archive_menu_config = archive_menu_config
        @version_control_system = version_control_system
        @file_system_accessor = file_system_accessor
        @static_site_generator = static_site_generator
        @sitemap_writer = sitemap_writer
        @final_app_directory = final_app_directory
        @context_dir = context_dir
        @preprocessor = preprocessor
        @cloner_factory = cloner_factory
        @dita_section_gatherer_factory = dita_section_gatherer_factory
        @section_repository_factory = section_repository_factory
        @command_creator = command_creator
        @sheller = sheller
        @directory_preparer = directory_preparer
      end

      def usage
        ["bind <local|remote> [--verbose] [--dita-flags='<dita-option>=<value>']",
         "Bind the sections specified in config.yml from <local> or <remote> into the final_app directory"]
      end

      def command_for?(test_command_name)
        %w(bind publish).include?(test_command_name)
      end

      def deprecated_command_for?(command_name)
        %w(publish).include?(command_name)
      end

      def run(cli_arguments)
        bind_source, *options = cli_arguments
        validate(bind_source, options)
        bind_config = config_factory.produce(bind_source)

        output_locations = OutputLocations.new(
          context_dir: context_dir,
          final_app_dir: final_app_directory,
          layout_repo_dir: layout_repo_path(bind_config, generate_local_repo_dir(context_dir, bind_source)),
          local_repo_dir: generate_local_repo_dir(context_dir, bind_source)
        )
        cloner = cloner_factory.produce(output_locations.local_repo_dir)
        section_repository = section_repository_factory.produce(cloner)

        output_streams = Streams::SwitchableStdoutAndRedStderr.new(options)

        directory_preparer.prepare_directories(
          bind_config,
          File.expand_path('../../../../', __FILE__),
          output_locations
        )

        sections = section_repository.fetch(
          configured_sections: bind_config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: ('master' if options.include?('--ignore-section-refs'))
        )
        dita_gatherer = dita_section_gatherer_factory.produce(bind_source, output_locations)
        gathered_dita_sections = dita_gatherer.gather(bind_config.dita_sections)

        preprocessor.preprocess(sections + gathered_dita_sections,
                                output_locations,
                                options: options,
                                output_streams: output_streams)

        subnavs = (sections + gathered_dita_sections).map(&:subnav).reduce(&:merge)

        success = publish(
          subnavs,
          {verbose: options.include?('--verbose')},
          output_locations,
          archive_menu_config.generate(bind_config, sections),
          cloner
        )

        success ? 0 : 1
      end

      private

      attr_reader :version_control_system,
                  :config_factory,
                  :archive_menu_config,
                  :logger,
                  :file_system_accessor,
                  :static_site_generator,
                  :final_app_directory,
                  :sitemap_writer,
                  :context_dir,
                  :preprocessor,
                  :cloner_factory,
                  :dita_section_gatherer_factory,
                  :section_repository_factory,
                  :command_creator,
                  :sheller,
                  :directory_preparer

      def publish(subnavs, cli_options, output_locations, publish_config, cloner)
        FileUtils.cp 'redirects.rb', output_locations.final_app_dir if File.exists?('redirects.rb')

        host_for_sitemap = publish_config.public_host

        static_site_generator.run(output_locations,
                                  publish_config,
                                  cloner,
                                  cli_options[:verbose],
                                  subnavs)
        file_system_accessor.copy output_locations.build_dir, output_locations.public_dir


        result = generate_sitemap(host_for_sitemap)

        logger.log "Bookbinder bound your book into #{output_locations.final_app_dir.to_s.green}"

        !result.has_broken_links?
      end

      def generate_sitemap(host_for_sitemap)
        raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)
        sitemap_writer.write(host_for_sitemap)
      end

      def generate_local_repo_dir(context_dir, bind_source)
        File.expand_path('..', context_dir) if bind_source == 'local'
      end

      def layout_repo_path(config, local_repo_dir)
        if local_repo_dir && config.has_option?('layout_repo')
          File.join(local_repo_dir, config.layout_repo.split('/').last)
        elsif config.has_option?('layout_repo')
          cloner = cloner_factory.produce(nil)
          working_copy = cloner.call(source_repo_name: config.layout_repo,
                                     destination_parent_dir: Dir.mktmpdir)
          working_copy.path
        else
          File.absolute_path('master_middleman')
        end
      end

      def validate(bind_source, options)
        raise CliError::InvalidArguments unless arguments_are_valid?(bind_source, options)
      end

      def arguments_are_valid?(bind_source, options)
        valid_options = %w(--verbose --ignore-section-refs --dita-flags).to_set
        %w(local remote github).include?(bind_source) && flag_names(options).to_set.subset?(valid_options)
      end

      def flag_names(opts)
        opts.map {|o| o.split('=').first}
      end
    end
  end
end
