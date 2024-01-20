# frozen_string_literal: true

require 'spec_helper'

class AssociationTestBase < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'
end

class Farm < AssociationTestBase
  schema do
    integer :id
    string :city
  end

  has_many :animals
end

class Animal < AssociationTestBase
  schema do
    integer :id, :farm_id
    string :name
  end

  belongs_to :farm
  has_one :favourite_food, class_name: 'Food'
end

class Food < AssociationTestBase
  schema do
    integer :id
    string :name
  end
end

class Image < AssociationTestBase
  schema do
    integer :id, :imageable_id
    string :url, :imageable_type
  end

  belongs_to :imageable, polymorphic: true
end

RSpec.describe 'associations' do
  let(:farm_attributes) do
    {
      id: 1,
      city: 'Tahiti'
    }
  end

  let(:animal_attributes) do
    {
      id: 1,
      farm_id: 1,
      name: 'Paddington'
    }
  end

  let(:food_attributes) do
    {
      id: 1,
      animal_id: 1,
      name: 'salad'
    }
  end

  describe 'belongs_to' do
    specify do
      dog = Animal.new(farm_id: 1).tap { |d| d.farm_id = 1 }

      stub_request(:GET, 'https://example.org/farms/1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: farm_attributes.to_json, headers: {})

      farm = dog.farm
      expect(farm).to be_a(Farm)
      expect(farm.id).to eq(1)
      expect(farm.city).to eq('Tahiti')
    end
  end

  describe 'polymorphic belongs_to' do
    specify do
      image = Image.new.tap do |i|
        i.imageable_type = 'Animal'
        i.imageable_id = 1
      end

      stub_request(:GET, 'https://example.org/animals/1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: animal_attributes.to_json, headers: {})

      animal = image.imageable

      expect(animal).to be_a(Animal)
      expect(animal.id).to eq(1)
      expect(animal.name).to eq('Paddington')
    end
  end

  describe 'has_one' do
    specify do
      dog = Animal.new.tap { |d| d.id = 1 }
      stub_request(:GET, 'https://example.org/foods?animal_id=1&limit=1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [food_attributes].to_json, headers: {})

      food = dog.favourite_food

      expect(food).to be_a(Food)
      expect(food.id).to eq(1)
      expect(food.name).to eq('salad')
    end
  end

  describe 'has_many' do
    specify do
      farm = Farm.new.tap { |f| f.id = 1 }

      stub_request(:GET, 'https://example.org/animals?farm_id=1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: [animal_attributes].to_json, headers: {})

      expect(farm.animals).to be_a(Hawk::Model::Proxy)

      collection = farm.animals.all
      expect(collection).to be_a(Hawk::Model::Collection)
      expect(collection.size).to eq(1)

      record = collection.first
      expect(record.name).to eq('Paddington')
    end
  end
end
