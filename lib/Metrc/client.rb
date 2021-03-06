module Metrc
  include Constants
  include Errors

  class Client
    include HTTParty
    headers 'Content-Type' => 'application/json'

    attr_accessor :debug,
                  :response,
                  :user_key,
                  :parsed_response,
                  :uri

    def initialize(opts = {})
      self.debug = opts[:debug]
      self.user_key = opts[:user_key]
      self.class.base_uri build_uri
      sign_in
    end

    ## CIM Common Interface Methods
    ## Metrc / BioTrackTHC / LeafData

    def retrieve(barcode)
      get_package(barcode)
      response.parsed_response.is_a?(Hash) ? response.parsed_response : nil
    end

    def api_get(url, options = {})
      options[:basic_auth] = auth_headers
      puts "\nMetrc API Request debug\nclient.get('#{self.uri}/#{url}', #{options})\n########################\n" if debug
      self.response = self.class.get(url, options)
      raise_request_errors

      puts "\nMetrc API Response debug\n#{response.to_s[0..360]}\n[200 OK]\n########################\n" if debug

      response
    end

    def api_post(url, options = {})
      options[:basic_auth] = auth_headers
      puts "\nMetrc API Request debug\nclient.post('#{self.uri}/#{url}', #{options})\n########################\n" if debug
      self.response = self.class.post(url, options)
      raise_request_errors

      puts "\nMetrc API Response debug\n#{response.to_s[0..360]}\n[200 OK]\n########################\n" if debug

      response
    end

    def api_delete(url, options = {})
      options[:basic_auth] = auth_headers
      puts "\nMetrc API Request debug\nclient.delete('#{self.uri}/#{url}', #{options})\n########################\n" if debug
      self.response = self.class.delete(url, options)
      raise_request_errors

      puts "\nMetrc API Response debug\n#{response.to_s[0..360]}\n[200 OK]\n########################\n" if debug

      response
    end

    def api_put(url, options = {})
      options[:basic_auth] = auth_headers
      puts "\nMetrc API Request debug\nclient.put('#{self.uri}/#{url}',, #{options})\n########################\n" if debug
      self.response = self.class.put(url, options)
      raise_request_errors

      puts "\nMetrc API Response debug\n#{response.to_s[0..360]}\n[200 OK]\n########################\n" if debug

      response
    end

    # GET
    def get_room(id)
      get(:rooms, id)
    end

    def get_package(id)
      get(:packages, id)
    end

    def get_strain(id)
      get(:strains, id)
    end

    def get_harvest(license_number, id)
      api_get("/harvests/v1/#{id}?licenseNumber=#{license_number}")
    end

    def get(resource, resource_id)
      api_get("/#{resource}/v1/#{resource_id}")
    end

    def post(resource, resource_id, license_number, resources)
      api_post("/#{resource}/v1/#{resource_id}?licenseNumber=#{license_number}", body: resources.to_json)
    end

    # LIST
    def list_rooms(license_number)
      list(:rooms, license_number)
    end

    def list_strains(license_number)
      list(:strains, license_number)
    end

    def list_transfer_templates(license_number, range_start: nil, range_end: nil)
      query_params = {}.tap do |hash|
        hash['licenseNumber'] = license_number
        hash['lastModifiedStart'] = range_start unless range_start.nil?
        hash['lastModifiedEnd'] = range_end unless range_end.nil?
      end

      api_get("/transfers/v1/templates?#{URI.encode_www_form(query_params)}")
    end

    def list_harvests(license_number, range_start: nil, range_end: nil)
      query_params = {}.tap do |hash|
        hash['licenseNumber'] = license_number
        hash['lastModifiedStart'] = range_start unless range_start.nil?
        hash['lastModifiedEnd'] = range_end unless range_end.nil?
      end

      api_get("/harvests/v1/active?#{URI.encode_www_form(query_params)}")
    end

    def list(resource, license_number)
      api_get("/#{resource}/v1/active?licenseNumber=#{license_number}").sort_by {|el| el['Id'] }
    end

    # CREATE
    def create_rooms(license_number, resources)
      create(:rooms, license_number, resources)
    end

    def create_strains(license_number, resources)
      create(:strains, license_number, resources)
    end

    def create_plant_batches(license_number, resources)
      api_post("/plantbatches/v1/createplantings?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def move_plant_batches(license_number, resources)
      api_put("/plantbatches/v1/moveplantbatches?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def change_growth_phase(license_number, resources)
      api_post("/plantbatches/v1/changegrowthphase?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def destroy_plant_batches(license_number, resources)
      api_post("/plantbatches/v1/destroy?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create_plant_batch_package(license_number, resources)
      api_post("/plantbatches/v1/createpackages?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create_plant_batch_from_mother(license_number, resources)
      api_post("/plants/v1/create/plantings?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create_plant_batch_package_from_mother(license_number, resources)
      api_post("/plantbatches/v1/create/packages/frommotherplant?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def split_plant_batch(license_number, resources)
      api_post("/plantbatches/v1/split?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def list_plant_batches(license_number)
      api_get("/plantbatches/v1/active?licenseNumber=#{license_number}")
    end

    def create_harvest_package(license_number, resources, for_testing = false)
      api_post("/harvests/v1/create/packages#{for_testing ? '/testing' : ''}?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create_plantings_package(license_number, resources)
      api_post("/packages/v1/create/plantings?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create_package(license_number, resources, for_testing = false)
      api_post("/packages/v1/create#{for_testing ? '/testing' : ''}?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def change_package_item(license_number, resources)
      api_post("/packages/v1/change/item?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def adjust_package(license_number, resources)
      api_post("/packages/v1/adjust?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def finish_package(license_number, resources)
      api_post("/packages/v1/finish?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def unfinish_package(license_number, resources)
      api_post("/packages/v1/unfinish?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def move_harvest(license_number, resources)
      api_put("/harvests/v1/move?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def finish_harvest(license_number, resources)
      api_post("/harvests/v1/finish?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def remove_waste(license_number, resources)
      api_post("/harvests/v1/removewaste?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create_transfer_template(license_number, resources)
      api_post("/transfers/v1/templates?licenseNumber=#{license_number}", body: resources.to_json)
    end

    def create(resource, license_number, resources)
      api_post("/#{resource}/v1/create?licenseNumber=#{license_number}", body: resources.to_json)
    end

    # UPDATE
    def update_rooms(license_number, resources)
      update(:rooms, license_number, resources)
    end

    def update_strains(license_number, resources)
      update(:strains, license_number, resources)
    end

    def update(resource, license_number, resources)
      api_post("/#{resource}/v1/update?licenseNumber=#{license_number}", body: resources.to_json)
    end

    # DELETE
    def delete_room(license_number, id)
      delete(:rooms, license_number, id)
    end

    def delete_strain(license_number, id)
      delete(:strains, license_number, id)
    end

    def delete_transfer_template(license_number, id)
      delete(:transfers, license_number, "templates/#{id}")
    end

    def delete(resource, license_number, resource_id)
      api_delete("/#{resource}/v1/#{resource_id}?licenseNumber=#{license_number}")
    end

    # LABORATORY RESULTS
    def labtest_states
      @labtest_states ||= api_get('/labtests/v1/states')
    end

    def labtest_types
      @labtest_types ||= api_get('/labtests/v1/types').sort_by {|el| el['Id'] }
    end

    def create_results(label, license_number, results = [], results_date = Time.now.utc.iso8601)
      get_package(label)
      raise Errors::NotFound.new("Package `#{label}` not found") if response.parsed_response.nil?

      api_post(
        "/labtests/v1/record?licenseNumber=#{license_number}",
        body: [
          {
            Label: label,
            ResultDate: results_date,
            Results: sanitize(results)
          }
        ].to_json
      )
    end

    # PLANTS
    def move_plants(license_number, resources)
      post(:plants, :moveplants, license_number, resources)
    end

    def destroy_plants(license_number, resources)
      post(:plants, :destroyplants, license_number, resources)
    end

    def manicure_plants(license_number, resources)
      post(:plants, :manicureplants, license_number, resources)
    end

    def harvest_plants(license_number, resources)
      post(:plants, :harvestplants, license_number, resources)
    end

    def change_plant_growth_phase(license_number, resources)
      post(:plants, :changegrowthphases, license_number, resources)
    end

    def sanitize(results)
      allowed_test_types = labtest_types.map {|el| el['Name'] }

      results.select {|result| !allowed_test_types.include?(result[:LabTestTypeName]) } # rubocop:disable Style/InverseMethods
    end

    def signed_in?
      true
    end

    private

    def auth_headers
      # change configuration.user_key to use database user_key
      { username: configuration.api_key, password: user_key }
    end

    def sign_in
      raise Errors::MissingConfiguration if configuration.incomplete?

      true
    end

    def configuration
      Metrc.configuration
    end

    def build_uri
      return self.uri if self.uri

      config   = configuration
      self.uri = "api-#{config.state}.metrc.com"

      self.uri.prepend('sandbox-') if config.sandbox

      self.uri.prepend('https://')
      self.uri
    end

    def raise_request_errors # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return if response.success?

      raise Errors::BadRequest.new("An error has occurred while executing your request. #{Metrc::Errors.parse_request_errors(response: response)}") if response.bad_request?
      raise Errors::Unauthorized.new('Invalid or no authentication provided.') if response.unauthorized?
      raise Errors::Forbidden.new('The authenticated user does not have access to the requested resource.') if response.forbidden?
      raise Errors::NotFound.new('The requested resource could not be found (incorrect or invalid URI).') if response.not_found?
      raise Errors::TooManyRequests.new('The limit of API calls allowed has been exceeded. Please pace the usage rate of the API more apart.') if response.too_many_requests?
      raise Errors::InternalServerError.new('An error has occurred while executing your request.') if response.server_error?
    end
  end
end
