require 'fog'
require 'tmpdir'
require 'ansi'
require 'faraday'
require 'faraday_middleware'
require 'octokit'
require 'middleman-syntax'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'anemone'
require 'css_parser'
require 'vienna'

require_relative 'bookbinder/shell_out'
require_relative 'bookbinder/bookbinder_logger'
require_relative 'bookbinder/git_client'
require_relative 'bookbinder/repository'
require_relative 'bookbinder/chapter'
require_relative 'bookbinder/book'
require_relative 'bookbinder/code_example'
require_relative 'bookbinder/credential_provider'
require_relative 'bookbinder/configuration'
require_relative 'bookbinder/sieve'
require_relative 'bookbinder/stabilimentum'
require_relative 'bookbinder/spider'

require_relative 'bookbinder/archive'
require_relative 'bookbinder/pdf_generator'
require_relative 'bookbinder/middleman_runner'
require_relative 'bookbinder/publisher'
require_relative 'bookbinder/doc_repo_change_monitor'
require_relative 'bookbinder/cf_command_runner'
require_relative 'bookbinder/pusher'
require_relative 'bookbinder/artifact_namer'
require_relative 'bookbinder/distributor'

require_relative 'bookbinder/bookbinder_command'
require_relative 'bookbinder/commands/build_and_push_tarball'
require_relative 'bookbinder/commands/doc_repos_updated'
require_relative 'bookbinder/commands/publish'
require_relative 'bookbinder/commands/push_local_to_staging'
require_relative 'bookbinder/commands/push_to_prod'
require_relative 'bookbinder/commands/run_publish_ci'
require_relative 'bookbinder/commands/update_local_doc_repos'
require_relative 'bookbinder/commands/tag'

require_relative 'bookbinder/cli'

# Finds the project root for both spec & production
GEM_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
