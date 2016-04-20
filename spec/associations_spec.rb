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
