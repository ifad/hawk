require 'spec_helper'

describe 'namespacing and subclassing' do
  class Cat < Hawk::Model::Base
    url "https://example.org/"
    client_name "Foobar"

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

  let(:cats_json) { [{id: 1, name: "Godzilla"}].to_json }

  describe 'name and module resolution' do
    context 'top-level classes' do
      specify do
        stub_request(:GET, "https://example.org/cats?limit=1").
          with(:headers => {'User-Agent'=>'Foobar'}).
          to_return(:status => 200, :body => cats_json, :headers => {})
        object = Cat.first

        expect(object.class).to eq(Cat)
      end
    end

    context 'top-level classes' do
      specify do
        stub_request(:GET, "https://example.org/big_cats?limit=1").
          with(:headers => {'User-Agent'=>'Foobar'}).
          to_return(:status => 200, :body => cats_json, :headers => {})

        object = BigCat.first
        expect(object.class).to eq(BigCat)
        expect(object).to be_kind_of(Cat)
      end
    end

    context 'different module, same name' do
      specify do
        stub_request(:GET, "https://example.org/cats?limit=1").
          with(:headers => {'User-Agent'=>'Foobar'}).
          to_return(:status => 200, :body => cats_json, :headers => {})

        object = AnotherModule::Cat.first
        expect(object.class).to eq(AnotherModule::Cat)
        expect(object).to be_kind_of(Cat)
      end
    end

    context 'different module, different name' do
      specify do
        stub_request(:GET, "https://example.org/big_cats?limit=1").
          with(:headers => {'User-Agent'=>'Foobar'}).
          to_return(:status => 200, :body => cats_json, :headers => {})

        object = AnotherModule::BigCat.first
        expect(object.class).to eq(AnotherModule::BigCat)
        expect(object).to be_kind_of(Cat)
      end
    end


  end
end


