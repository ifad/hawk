require 'spec_helper'

describe 'error handling' do
  class Failure < Hawk::Model::Base
    url "https://example.org/"
    client_name "Foobar"
  end

  it 'raises an exception when the record is missing' do
    stub_request(:GET, "https://example.org/failures/404").
             with(:headers => {'User-Agent'=>'Foobar'}).
             to_return(:status => 404, :body => "Not found", :headers => {})

    expect { Failure.find(404) }.to raise_error(Hawk::Error::NotFound)
  end

  it 'raises an exception when the server returns an HTTP 500' do
    stub_request(:GET, "https://example.org/failures/500").
             with(:headers => {'User-Agent'=>'Foobar'}).
             to_return(:status => 500, :body => ":(", :headers => {})

    expect { Failure.find(500) }.to raise_error(Hawk::Error::InternalServerError)
  end

  it 'raises an exception when the server returns unexpected HTTP codes' do
    stub_request(:GET, "https://example.org/failures/666").
             with(:headers => {'User-Agent'=>'Foobar'}).
             to_return(:status => 666, :body => "{}", :headers => {})

    expect { Failure.find(666) }.to raise_error(Hawk::Error)
  end

  it 'raises an exception when the server times out' do
    stub_request(:GET, "https://example.org/failures/123").
             with(:headers => {'User-Agent'=>'Foobar'}).
             to_timeout

    expect { Failure.find(123) }.to raise_error(Hawk::Error::Timeout)
  end
end
