# frozen_string_literal: true

require 'spec_helper'

class Car < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

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

RSpec.describe 'schema' do
  specify do
    expect(Car.schema).to be_a(Hash)
  end

  it 'casts the values correctly' do
    car = Car.new({
                    'id' => '1',
                    'brand' => 'skoda',
                    'hybrid' => 'true',
                    'hp' => '123.45',
                    'owners_birthday' => '2015-12-31',
                    'created_at' => '2015-12-31 23:59:59',
                    'price' => '999999999999999999999'
                  })

    expect(car.id).to be_a(Integer)
    expect(car.brand).to be_a(String)
    expect(car.hybrid).to be_a(TrueClass)
    expect(car.hp).to be_a(Float)
    expect(car.owners_birthday).to be_a(Date)
    expect(car.created_at).to be_a(Time)
    expect(car.price).to be_a(BigDecimal)
  end
end
