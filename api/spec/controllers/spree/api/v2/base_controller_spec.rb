require 'spec_helper'

class DummyController < Spree::Api::V2::BaseController
  private

  def default_resource_includes
    %w[variants images]
  end
end

describe Spree::Api::V2::BaseController, type: :controller do
  let(:dummy_controller) { DummyController.new }

  describe '#default_resource_includes' do
    context 'not implemented' do
      it 'returns an empty array' do
        expect(controller.send(:default_resource_includes)).to eq([])
      end
    end

    context 'implemented' do
      it 'overrides the method' do
        expect(dummy_controller.send(:default_resource_includes)).to eq(%w[variants images])
      end
    end
  end

  describe '#resource_includes' do
    context 'passed as params' do
      before do
        dummy_controller.params = { include: 'variants,images,taxons' }
      end

      it 'returns included resources specified in params' do
        expect(dummy_controller.send(:resource_includes)).to eq([:variants, :images, :taxons])
      end
    end

    context 'not passed in params' do
      before do
        dummy_controller.params = {}
      end

      it 'returns default resources' do
        expect(dummy_controller.send(:resource_includes)).to eq([:variants, :images])
      end
    end
  end

  describe '#sparse_fields' do
    shared_examples 'invalid params format' do
      it 'returns nil' do
        expect(dummy_controller.send(:sparse_fields)).to eq(nil)
      end
    end

    context 'not passed in params' do
      before do
        dummy_controller.params = {}
      end

      it_behaves_like 'invalid params format'
    end

    context 'with no field type specified' do
      before do
        dummy_controller.params = { fields: 'name,slug,price' }
      end

      it_behaves_like 'invalid params format'
    end

    context 'with type values not comma separated' do
      before do
        dummy_controller.params = { fields: { product: { values: 'name,slug,price' } } }
      end

      it_behaves_like 'invalid params format'
    end

    context 'with valid params format' do
      before do
        dummy_controller.params = { fields: { product: 'name,slug,price' } }
      end

      it 'returns specified params' do
        expect(dummy_controller.send(:sparse_fields)).to eq(product: [:name, :slug, :price])
      end
    end
  end

  describe '#error_during_processing' do
    controller(described_class) do
      def index
        render plain: { 'products' => [] }.to_json
      end
    end

    before do
      @routes = ActionDispatch::Routing::RouteSet.new.tap do |r|
        r.draw { get 'index', to: 'spree/api/v2/base#index' }
      end
    end

    let!(:user) { create :user }
    let(:exception) { ArgumentError.new('foo') }
    let(:result_class) { Struct.new(:value) }
    let(:result) { result_class.new({message: 'foo'}) }

    it 'handles ArgumentError exceptions' do
      expect(subject).to receive(:index).and_raise(exception)
      expect(subject).to receive(:spree_current_user).and_return(user)
      expect_next_instance_of(::Spree::Api::ErrorHandler) do |instance|
        expect(instance).to receive(:call).with(
          exception: exception,
          opts: { user: user }
        ).and_return(result)
      end
      get :index, params: { token: 'exception-message' }
      expect(json_response).to eql('error' => 'foo')
    end
  end

  describe '#serializer_params' do
    let(:store) { Spree::Store.default }
    let(:currency) { store.default_currency }
    let(:locale) { store.default_locale }
    let(:user) { nil }

    shared_examples 'returns proper values' do
      before do
        allow(dummy_controller).to receive(:current_store).and_return(store)
        allow(dummy_controller).to receive(:current_currency).and_return(currency)
        allow(dummy_controller).to receive(:current_locale).and_return(locale)
        allow(dummy_controller).to receive(:spree_current_user).and_return(user)
      end

      it { expect(dummy_controller.send(:serializer_params).keys).to eq(%i[currency locale store user]) }

      it do
        expect(dummy_controller.send(:serializer_params)).to eq(
          {
            store: store,
            currency: currency,
            user: user,
            locale: locale
          }
        )
      end
    end

    context 'default values' do
      it_behaves_like 'returns proper values'
    end

    context 'non-default values' do
      let(:user) { create(:user) }
      let(:currency) { 'EUR' }
      let(:locale) { 'de' }
      let(:store) { create(:store, default_locale: locale, default_currency: currency) }

      it_behaves_like 'returns proper values'
    end
  end
end
