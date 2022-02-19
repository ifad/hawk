require 'spec_helper'

describe 'collections and pagination' do
  class Mosquito < Hawk::Model::Base
    url "https://example.org/"
    client_name "Foobar"

    schema do
      integer :id
      string :name
    end
  end

  describe 'collection behaviour' do
    let(:collection_as_an_array) {
      [
        {id: 1, name: 'bzzz'},
        {id: 2, name: 'bzbzzzz'},
        {id: 3, name: 'bzzzzbzbzzz'}
      ]
    }

    let(:collection_as_a_hash) {
      {
        mosquitos: collection_as_an_array,
        total_count: 123,
        limit: 20,
        offset: 50
      }
    }

    describe 'collection as an array' do
      specify do
        stub_request(:GET, "https://example.org/mosquitos"). # pluralization can be improved
          with(:headers => {'User-Agent'=>'Foobar'}).
          to_return(:status => 200, :body => collection_as_an_array.to_json, :headers => {})
        collection = Mosquito.all
        expect(collection.size).to eq(3)
      end
    end

    describe 'collection as a hash' do
      specify do
        stub_request(:GET, "https://example.org/mosquitos").
          with(:headers => {'User-Agent'=>'Foobar'}).
          to_return(:status => 200, :body => collection_as_a_hash.to_json, :headers => {})
        collection = Mosquito.all
        expect(collection.size).to eq(3)
      end
    end

  end

  describe '.count' do
    before do
      stub_request(:GET, "https://example.org/mosquitos/count").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(:status => 200, :body => {count: 123}.to_json, :headers => {})
    end

    specify do
      expect(Mosquito.count).to eq(123)
    end

    context 'when parameter is not a hash' do
      specify do
        expect { Mosquito.count(:all) }.not_to raise_error
      end
    end
  end
end
