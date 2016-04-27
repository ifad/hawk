require 'spec_helper'

describe 'associations' do
  class AssociationTestBase  < Hawk::Model::Base
    url "http://zombo.com/"
    client_name "Foobar"
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
    has_one :favourite_food, class_name: "Food"
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

  let(:farm_attributes) {
    {
      id: 1,
      city: 'Tahiti'
    }
  }

  let(:animal_attributes) {
    {
      id: 1,
      farm_id: 1,
      name: 'Paddington'
    }
  }

  let(:food_attributes) {
    {
      id: 1,
      animal_id: 1,
      name: 'salad'
    }
  }

  describe 'belongs_to' do
    specify do
      dog = Animal.new(farm_id: 1).tap{|d| d.farm_id = 1}

      stub_request(:GET, "http://zombo.com/farms/1").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(:status => 200, :body => farm_attributes.to_json, :headers => {})

      farm = dog.farm
      expect(farm).to be_kind_of(Farm)
      expect(farm.id).to eq(1)
      expect(farm.city).to eq('Tahiti')
    end
  end

  describe 'polymorphic belongs_to' do
    specify do
      image = Image.new.tap{|i| i.imageable_type = "Animal"; i.imageable_id = 1}

      stub_request(:GET, "http://zombo.com/animals/1").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(:status => 200, :body => animal_attributes.to_json, :headers => {})

      animal = image.imageable

      expect(animal).to be_kind_of(Animal)
      expect(animal.id).to eq(1)
      expect(animal.name).to eq('Paddington')
    end
  end

  describe 'has_one' do
    specify do
      dog = Animal.new.tap{|d| d.id = 1}
      stub_request(:GET, "http://zombo.com/foods?animal_id=1&limit=1").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(:status => 200, :body => [food_attributes].to_json, :headers => {})

      food = dog.favourite_food

      expect(food).to be_kind_of(Food)
      expect(food.id).to eq(1)
      expect(food.name).to eq('salad')
    end
  end

  describe 'has_many' do
    specify do
      farm = Farm.new.tap{|f| f.id = 1}

      stub_request(:GET, "http://zombo.com/animals?farm_id=1").
        with(:headers => {'User-Agent'=>'Foobar'}).
        to_return(:status => 200, :body => [animal_attributes].to_json, :headers => {})

      expect(farm.animals).to be_kind_of(Hawk::Model::Proxy)

      collection = farm.animals.all
      expect(collection).to be_kind_of(Hawk::Model::Collection)
      expect(collection.size).to eq(1)

      record = collection.first
      expect(record.name).to eq("Paddington")
    end
  end

end
