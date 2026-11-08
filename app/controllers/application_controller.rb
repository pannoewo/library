class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_invalid_json

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def render_bad_request(error)
    render json: { errors: [ error.message ] }, status: :bad_request
  end

  def render_invalid_json(_error)
    render json: { errors: [ "Malformed JSON request body" ] }, status: :bad_request
  end
end
