require 'spec_helper'

describe 'schema' do
  class Car < Hawk::Model::Base
    url "http://zombo.com/"
    client_name "Foobar"

    schema do
      integer :id
      string :brand
      boolean :hybrid
      float :hp
      date :owners_birthday
      datetime :created_at
      bignum :price
    end
  end

  specify do
    expect(Car.schema).to be_kind_of(Hash)
  end

  it 'casts the values correctly' do
    car = Car.new({
      "id" => "1",
      "brand" => "skoda",
      "hybrid" => "true",
      "hp" => "123.45",
      "owners_birthday" => "2015-12-31",
      "created_at" => "2015-12-31 23:59:59",
      "price" => "999999999999999999999"
    })

    expect(car.id).to be_kind_of(Fixnum)
    expect(car.brand).to be_kind_of(String)
    expect(car.hybrid).to be_kind_of(TrueClass)
    expect(car.hp).to be_kind_of(Float)
    expect(car.owners_birthday).to be_kind_of(Date)
    expect(car.created_at).to be_kind_of(Time)
    expect(car.price).to be_kind_of(BigDecimal)
  end
end
