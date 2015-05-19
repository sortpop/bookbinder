require_relative '../../../../lib/bookbinder/preprocessing/copy_to_site_gen_dir'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  module Preprocessing
    describe CopyToSiteGenDir do
      it 'is applicable to sections without dita subnavs' do
        regular_section = Section.new
        preprocessor = CopyToSiteGenDir.new(double('filesystem'))
        expect(preprocessor).to be_applicable_to(regular_section)
      end

      it 'is not applicable to sections with dita subnavs' do
        dita_subnav_section = Section.new(nil, nil, nil, nil, nil, 'dita_subnav')
        preprocessor = CopyToSiteGenDir.new(double('filesystem'))
        expect(preprocessor).not_to be_applicable_to(dita_subnav_section)
      end

      it 'just copies sections from their cloned dir to the dir ready for site generation' do
        fs = double('filesystem')
        preprocessor = CopyToSiteGenDir.new(fs)
        output_locations = OutputLocations.new(context_dir: 'mycontextdir')
        sections = [
          Section.new(
            'path1',
            'myorg/myrepo',
            copied = true,
            'irrelevant/dest/dir',
            'my/desired/dir'
          ),
          Section.new(
            'path2',
            'myorg/myrepo2',
            copied = true,
            'irrelevant/other/dest/dir',
            desired_dir = nil
          )
        ]

        expect(fs).to receive(:copy_contents).with(
          sections[0].path_to_repository,
          output_locations.source_for_site_generator.join('my/desired/dir')
        )
        expect(fs).to receive(:copy_contents).with(
          sections[1].path_to_repository,
          output_locations.source_for_site_generator.join('myrepo2')
        )

        preprocessor.preprocess(sections, output_locations, 'unused', 'args')
      end
    end
  end
end
