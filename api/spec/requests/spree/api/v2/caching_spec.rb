require 'spec_helper'

describe 'API v2 Caching spec', type: :request do
  let!(:product) { create(:product, name: 'Some name', stores: [store]) }
  let(:store) { Spree::Store.default }

  let(:cache_store) { Spree::V2::Storefront::ProductSerializer.cache_store_instance }
  let(:cache_entry) { cache_store.read(product, namespace: cache_namespace) }

  before do
    ActionController::Base.perform_caching = true
  end

  after do
    ActionController::Base.perform_caching = false
    Rails.cache.clear
  end

  context 'auto expiration' do
    let(:cache_namespace) { "jsonapi-serializer-usd-en-#{store.cache_key_with_version}" }

    it 'auto expire cache after record being updated' do
      get "/api/v2/storefront/products/#{product.id}"

      expect(json_response['data']).to have_attribute('name').with_value('Some name')

      expect(cache_entry).not_to be_nil
      expect(cache_entry[:attributes].as_json).to eq(json_response[:data][:attributes])

      product.update(name: 'Something else')
      expect(cache_store.read(product, namespace: cache_namespace)).to be_nil

      get "/api/v2/storefront/products/#{product.id}"
      expect(cache_store.read(product, namespace: cache_namespace)).not_to be_nil
      expect(json_response['data']).to have_attribute('name').with_value('Something else')
    end
  end

  context 'currency and user' do
    include_context 'API v2 tokens'

    before { store.update!(supported_currencies: 'USD,EUR', supported_locales: 'en,de') }

    let!(:user) { create(:user) }
    let(:currency) { 'EUR' }
    let(:locale) { 'de' }
    let(:cache_namespace) { "jsonapi-serializer-eur-de-#{store.cache_key_with_version}-#{user.cache_key_with_version}" }

    it 'includes currency and signed user in the cache key' do
      get "/api/v2/storefront/products/#{product.id}?currency=#{currency}&locale=#{locale}", headers: headers_bearer

      expect(cache_entry).not_to be_nil
    end
  end
end
