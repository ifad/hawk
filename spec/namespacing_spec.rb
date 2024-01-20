# frozen_string_literal: true

require 'spec_helper'

class Cat < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

  schema do
    integer :id
    string :name
  end
end

class BigCat < Cat; end

module AnotherModule
  class Cat < ::Cat; end
  class BigCat < Cat; end
end

RSpec.describe 'namespacing and subclassing' do
  let(:cats_json) { [{ id: 1, name: 'Godzilla' }].to_json }

  describe 'name and module resolution' do
    context 'with top-level classes' do
      specify do
        stub_request(:GET, 'https://example.org/cats?limit=1')
          .with(headers: { 'User-Agent' => 'Foobar' })
          .to_return(status: 200, body: cats_json, headers: {})
        object = Cat.first

        expect(object.class).to eq(Cat)
      end

      specify do
        stub_request(:GET, 'https://example.org/big_cats?limit=1')
          .with(headers: { 'User-Agent' => 'Foobar' })
          .to_return(status: 200, body: cats_json, headers: {})

        object = BigCat.first
        expect(object.class).to eq(BigCat)
        expect(object).to be_a(Cat)
      end
    end

    context 'with different module, same name' do
      specify do
        stub_request(:GET, 'https://example.org/cats?limit=1')
          .with(headers: { 'User-Agent' => 'Foobar' })
          .to_return(status: 200, body: cats_json, headers: {})

        object = AnotherModule::Cat.first
        expect(object.class).to eq(AnotherModule::Cat)
        expect(object).to be_a(Cat)
      end
    end

    context 'with different module, different name' do
      specify do
        stub_request(:GET, 'https://example.org/big_cats?limit=1')
          .with(headers: { 'User-Agent' => 'Foobar' })
          .to_return(status: 200, body: cats_json, headers: {})

        object = AnotherModule::BigCat.first
        expect(object.class).to eq(AnotherModule::BigCat)
        expect(object).to be_a(Cat)
      end
    end
  end
end
