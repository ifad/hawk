# frozen_string_literal: true

require 'spec_helper'

class Person < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

  schema do
    integer :id
    string :name
  end

  scope :by_name, ->(q) { where(name: q) }
end

RSpec.describe 'basic operations with a class that inherits from Hawk::Model::Base' do
  let(:person_attributes) do
    {
      id: 2,
      name: 'Woody Allen'
    }
  end

  describe '.get' do
    it 'squeezes multiple slashes' do
      stub_request(:GET, 'https://example.org/people/batch/id')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [2].to_json, headers: {})

      expect(Person.get('/batch///id')).to contain_exactly(2)
    end
  end

  describe '.find(id)' do
    specify do
      stub_request(:GET, 'https://example.org/people/2')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: person_attributes.to_json, headers: {})

      person = Person.find(2)
      expect(person).to be_a(Person)
      expect(person.id).to eq(2)
      expect(person.name).to eq('Woody Allen')
    end
  end

  describe '.first' do
    specify do
      stub_request(:GET, 'https://example.org/people?limit=1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [person_attributes].to_json, headers: {})

      person = Person.first
      expect(person).to be_a(Person)
      expect(person.id).to eq(2)
      expect(person.name).to eq('Woody Allen')
    end
  end

  describe '.find_by' do
    it 'is an alias of first' do
      expect(Person.method(:find_by).original_name).to eq(:first)
    end
  end

  describe '.first!' do
    specify do
      stub_request(:GET, 'https://example.org/people?limit=1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 404, headers: {})

      expect do
        Person.first!
      end.to raise_error Hawk::Error::NotFound
    end
  end

  describe '.find_by!' do
    it 'is an alias of first!' do
      expect(Person.method(:find_by!).original_name).to eq(:first!)
    end
  end

  describe '.all' do
    specify do
      stub_request(:GET, 'https://example.org/people')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [person_attributes, person_attributes].to_json, headers: {})

      collection = Person.all
      expect(collection.size).to eq(2)
    end
  end

  describe '.where' do
    specify do
      stub_request(:GET, 'https://example.org/people?name=Zelig')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [person_attributes].to_json, headers: {})

      collection = Person.where(name: 'Zelig').all
      expect(collection.size).to eq(1)
    end
  end

  describe '.order' do
    specify do
      stub_request(:GET, 'https://example.org/people?order=name')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [person_attributes].to_json, headers: {})

      collection = Person.order(:name).all
      expect(collection.size).to eq(1)
    end
  end

  describe 'scoping' do
    it 'allows active_record-like scopes' do
      stub_request(:GET, 'https://example.org/people?limit=1&name=pluto')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [person_attributes].to_json, headers: {})
      person = Person.by_name('pluto').first
      expect(person).to be_a(Person)
    end
  end

  describe '#inspect' do
    it 'returns a string representation of the model' do
      stub_request(:GET, 'https://example.org/people/2')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: person_attributes.to_json, headers: {})

      person = Person.find(2)

      expect(person.inspect).to eq('#<Person id=2 name="Woody Allen">')
    end
  end
end
