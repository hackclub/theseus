# Base controller for toolchest OAuth UI pages (consent screen, authorized apps).
# Inherits app auth and layout but skips Pundit's verify_authorized,
# since toolchest controllers don't use Pundit.
class ToolchestController < ApplicationController
  skip_after_action :verify_authorized
end
