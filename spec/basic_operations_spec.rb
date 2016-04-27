require 'spec_helper'

describe 'basic operations with a class that inherits from Hawk::Model::Base' do
  class Person < Hawk::Model::Base
    url "http://zombo.com/"
    client_name "Foobar"

    schema do
      integer :id
      string :name
    end
  end

  let(:person_attributes) {
    {
      id: 2,
      name: "Woody Allen"
    }
  }

  describe '.find(id)' do
    specify do
      stub_request(:GET, "http://zombo.com/persons/2").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(status: 200, body: person_attributes.to_json, headers: {})

      person = Person.find(2)
      expect(person).to be_kind_of(Person)
      expect(person.id).to eq(2)
      expect(person.name).to eq("Woody Allen")
    end
  end

  describe '.first' do
    specify do
      stub_request(:GET, "http://zombo.com/persons?limit=1").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(status: 200, body: [person_attributes].to_json, headers: {})

      person = Person.first
      expect(person).to be_kind_of(Person)
      expect(person.id).to eq(2)
      expect(person.name).to eq("Woody Allen")
    end
  end

  describe '.all' do
    specify do
      stub_request(:GET, "http://zombo.com/persons").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(status: 200, body: [person_attributes, person_attributes].to_json, headers: {})

      collection = Person.all
      expect(collection.size).to eq(2)
    end
  end

  describe '.where' do
    specify do
      stub_request(:GET, "http://zombo.com/persons?name=Zelig").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(status: 200, body: [person_attributes].to_json, headers: {})

      collection = Person.where(name: 'Zelig').all
      expect(collection.size).to eq(1)
    end
  end

  describe '.order' do
    specify do
      stub_request(:GET, "http://zombo.com/persons?order=name").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(status: 200, body: [person_attributes].to_json, headers: {})

      collection = Person.order(:name).all
      expect(collection.size).to eq(1)
    end
  end

  describe 'scoping' do
    class Person < Hawk::Model::Base
      scope :by_name, ->(q) { where(name: q)}
    end

    it 'allows active_record-like scopes' do
      stub_request(:GET, "http://zombo.com/persons?limit=1&name=pluto").
               with(:headers => {'User-Agent'=>'Foobar'}).
               to_return(:status => 200, :body => [person_attributes].to_json, :headers => {})
      person = Person.by_name('pluto').first
      expect(person).to be_kind_of(Person)
    end
  end
end
