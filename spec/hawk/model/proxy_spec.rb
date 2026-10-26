# frozen_string_literal: true

require 'spec_helper'

class Gnat < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

  schema do
    integer :id
    string :name
  end
end

RSpec.describe Hawk::Model::Proxy do
  let(:proxy) { Gnat.where(kind: 'small') }

  def stub_page(page, ids)
    stub_request(:GET, 'https://example.org/gnats')
      .with(query: { kind: 'small', page: page.to_s })
      .to_return(status: 200, body: ids.map { |id| { id: id } }.to_json, headers: {})
  end

  describe '#all' do
    it 'requests again when params change' do
      first = stub_page(1, [1])
      second = stub_page(2, [2])

      expect(proxy.all(page: 1).map(&:id)).to eq([1])
      expect(proxy.all(page: 2).map(&:id)).to eq([2])
      expect(first).to have_been_requested.once
      expect(second).to have_been_requested.once
    end

    it 'reuses the result when no params are given' do
      base = stub_request(:GET, 'https://example.org/gnats')
             .with(query: { kind: 'small' })
             .to_return(status: 200, body: [{ id: 1 }].to_json, headers: {})

      proxy.all
      proxy.to_a
      expect(base).to have_been_requested.once
    end

    it 'does not replace the result with a parametrized one' do
      stub_request(:GET, 'https://example.org/gnats')
        .with(query: { kind: 'small' })
        .to_return(status: 200, body: [{ id: 1 }].to_json, headers: {})
      stub_page(2, [2])

      proxy.all
      proxy.all(page: 2)
      expect(proxy.map(&:id)).to eq([1])
    end

    it 'returns the collection after #find' do
      stub_request(:GET, 'https://example.org/gnats/9')
        .with(query: { kind: 'small' })
        .to_return(status: 200, body: { id: 9 }.to_json, headers: {})
      stub_request(:GET, 'https://example.org/gnats')
        .with(query: { kind: 'small' })
        .to_return(status: 200, body: [{ id: 1 }, { id: 2 }].to_json, headers: {})

      expect(proxy.find(9).id).to eq(9)
      expect(proxy.all.map(&:id)).to eq([1, 2])
    end
  end

  describe '#count' do
    it 'requests the count when params differ from the loaded result' do
      stub_request(:GET, 'https://example.org/gnats')
        .with(query: { kind: 'small' })
        .to_return(status: 200, body: [{ id: 1 }].to_json, headers: {})
      count = stub_request(:GET, 'https://example.org/gnats/count')
              .with(query: { kind: 'small', page: '2' })
              .to_return(status: 200, body: { count: 42 }.to_json, headers: {})

      proxy.all
      expect(proxy.count(page: 2)).to eq(42)
      expect(count).to have_been_requested.once
    end

    it 'uses the loaded result when no params are given' do
      stub_request(:GET, 'https://example.org/gnats')
        .with(query: { kind: 'small' })
        .to_return(status: 200, body: [{ id: 1 }, { id: 2 }].to_json, headers: {})

      proxy.all
      expect(proxy.count).to eq(2)
    end

    it 'accepts a non-hash argument such as :all' do
      stub_request(:GET, 'https://example.org/gnats').with(query: { kind: 'small' })
                                                     .to_return(status: 200, body: [{ id: 1 }, { id: 2 }].to_json, headers: {})

      proxy.all
      expect(proxy.count(:all)).to eq(2)
    end
  end

  describe 'Void' do
    let(:proxy) { Gnat.none }

    it 'returns empty results without requests' do
      expect(proxy.all).to eq([])
      expect(proxy.all(page: 1)).to eq([])
      expect(proxy.to_a).to eq([])
      expect(proxy.count).to eq(0)
      expect(proxy).to respond_to(:empty?)
      expect(a_request(:any, /example\.org/)).not_to have_been_made
    end
  end
end
