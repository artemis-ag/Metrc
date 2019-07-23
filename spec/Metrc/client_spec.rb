require 'spec_helper'

describe Metrc::Client do
  before(:each) do
    configure_client
  end

  let(:subject) { described_class.new(user_key: $spec_credentials['user_key']) }

  describe '#api_post' do
    let(:licenseNumber) { 'CML17-0000001' }
    let(:api_url) { "/foo/v1/bar?licenseNumber=#{licenseNumber}" }
    let(:api_post) { subject.api_post(api_url) }

    before(:each) do
      stub_request(:post, "#{$spec_credentials['base_uri']}#{api_url}")
        .to_return(status: status)
    end

    context 'Metrc API returns 400' do
      let(:status) { 400 }
      it 'raises an error' do
        expect { api_post }.to(raise_error(Metrc::Errors::BadRequest))
      end
    end

    context 'Metrc API returns 401' do
      let(:status) { 401 }
      it 'raises an error' do
        expect { api_post }.to(raise_error(Metrc::Errors::Unauthorized))
      end
    end

    context 'Metrc API returns 403' do
      let(:status) { 403 }
      it 'raises an error' do
        expect { api_post }.to(raise_error(Metrc::Errors::Forbidden))
      end
    end

    context 'Metrc API returns 404' do
      let(:status) { 404 }
      it 'raises an error' do
        expect { api_post }.to(raise_error(Metrc::Errors::NotFound))
      end
    end

    context 'Metrc API returns 429' do
      let(:status) { 429 }
      it 'raises an error' do
        expect { api_post }.to(raise_error(Metrc::Errors::TooManyRequests))
      end
    end

    context 'Metrc API returns 500' do
      let(:status) { 500 }
      it 'raises an error' do
        expect { api_post }.to(raise_error(Metrc::Errors::InternalServerError))
      end
    end
  end
end