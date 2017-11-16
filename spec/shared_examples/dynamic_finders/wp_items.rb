
shared_examples WPScan::Finders::DynamicFinder::WpItems::Finder do
  let(:passive_fixture) do
    File.join(fixtures, "#{described_class.to_s.demodulize.underscore}_passive_all.html")
  end

  describe '#passive_configs' do
    # Not sure if it's worth to do it as it's just a call to something tested
    # and an exception will be raised if the method called is wrong
  end

  describe '#aggressive_configs' do
    # Same as above
  end

  describe '#passive' do
    before do
      stub_request(:get, target.url).to_return(body: body)

      allow(target).to receive(:content_dir).and_return('wp-content')
    end

    context 'when no matches' do
      let(:body) { '' }

      it 'returns an empty array' do
        expect(finder.passive).to eql([])
      end
    end

    context 'when matches' do
      let(:body) { File.read(passive_fixture) }

      it 'contains the expected plugins' do
        expected = []

        finder.passive_configs.each do |slug, configs|
          configs.each_key do |finder_class|
            expected_finding_opts = expected_all[slug][finder_class]

            expected << item_class.new(
              slug,
              target,
              confidence: expected_finding_opts['confidence'] || default_confidence,
              found_by: expected_finding_opts['found_by']
            )
          end
        end

        expect(finder.passive).to match_array(expected.map { |item| eql(item) })
      end
    end
  end

  describe '#aggressive' do
    # TODO: Maybe also stub all paths to an empty body and expect an empty array ?

    before do
      @expected = []

      allow(target).to receive(:content_dir).and_return('wp-content')

      # Stubbing all requests to the different paths

      finder.aggressive_configs.each do |slug, configs|
        configs.each do |finder_class, config|
          finder_super_class = config['class'] ? config['class'] : finder_class

          fixture           = File.join(fixtures, slug, finder_class.underscore, config['path'])
          stubbed_response  = df_stubbed_response(fixture, finder_super_class)
          path              = finder.aggressive_path(slug, config)

          expected_finding_opts = expected_all[slug][finder_class]

          stub_request(:get, target.url(path)).to_return(stubbed_response)

          @expected << item_class.new(
            slug,
            target,
            confidence: expected_finding_opts['confidence'] || default_confidence,
            found_by: expected_finding_opts['found_by']
          )
        end
      end
    end

    it 'retuns the expected plugins' do
      expect(finder.aggressive).to match_array(@expected.map { |item| eql(item) })
    end
  end
end
