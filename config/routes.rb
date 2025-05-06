# == Route Map
#
#                                   Prefix Verb   URI Pattern                                                                                       Controller#Action
#                                                 /assets                                                                                           Propshaft::Server
#                    usps_payment_accounts GET    /usps/payment_accounts(.:format)                                                                  usps/payment_accounts#index
#                                          POST   /usps/payment_accounts(.:format)                                                                  usps/payment_accounts#create
#                 new_usps_payment_account GET    /usps/payment_accounts/new(.:format)                                                              usps/payment_accounts#new
#                edit_usps_payment_account GET    /usps/payment_accounts/:id/edit(.:format)                                                         usps/payment_accounts#edit
#                     usps_payment_account GET    /usps/payment_accounts/:id(.:format)                                                              usps/payment_accounts#show
#                                          PATCH  /usps/payment_accounts/:id(.:format)                                                              usps/payment_accounts#update
#                                          PUT    /usps/payment_accounts/:id(.:format)                                                              usps/payment_accounts#update
#                                          DELETE /usps/payment_accounts/:id(.:format)                                                              usps/payment_accounts#destroy
#                          usps_mailer_ids GET    /usps/mailer_ids(.:format)                                                                        usps/mailer_ids#index
#                                          POST   /usps/mailer_ids(.:format)                                                                        usps/mailer_ids#create
#                       new_usps_mailer_id GET    /usps/mailer_ids/new(.:format)                                                                    usps/mailer_ids#new
#                      edit_usps_mailer_id GET    /usps/mailer_ids/:id/edit(.:format)                                                               usps/mailer_ids#edit
#                           usps_mailer_id GET    /usps/mailer_ids/:id(.:format)                                                                    usps/mailer_ids#show
#                                          PATCH  /usps/mailer_ids/:id(.:format)                                                                    usps/mailer_ids#update
#                                          PUT    /usps/mailer_ids/:id(.:format)                                                                    usps/mailer_ids#update
#                                          DELETE /usps/mailer_ids/:id(.:format)                                                                    usps/mailer_ids#destroy
#                  usps_oauth2_connections GET    /usps/oauth2_connections(.:format)                                                                usps/oauth2_connections#index
#                                          POST   /usps/oauth2_connections(.:format)                                                                usps/oauth2_connections#create
#               new_usps_oauth2_connection GET    /usps/oauth2_connections/new(.:format)                                                            usps/oauth2_connections#new
#              edit_usps_oauth2_connection GET    /usps/oauth2_connections/:id/edit(.:format)                                                       usps/oauth2_connections#edit
#                   usps_oauth2_connection GET    /usps/oauth2_connections/:id(.:format)                                                            usps/oauth2_connections#show
#                                          PATCH  /usps/oauth2_connections/:id(.:format)                                                            usps/oauth2_connections#update
#                                          PUT    /usps/oauth2_connections/:id(.:format)                                                            usps/oauth2_connections#update
#                                          DELETE /usps/oauth2_connections/:id(.:format)                                                            usps/oauth2_connections#destroy
#                              source_tags GET    /source_tags(.:format)                                                                            source_tags#index
#                                          POST   /source_tags(.:format)                                                                            source_tags#create
#                           new_source_tag GET    /source_tags/new(.:format)                                                                        source_tags#new
#                          edit_source_tag GET    /source_tags/:id/edit(.:format)                                                                   source_tags#edit
#                               source_tag GET    /source_tags/:id(.:format)                                                                        source_tags#show
#                                          PATCH  /source_tags/:id(.:format)                                                                        source_tags#update
#                                          PUT    /source_tags/:id(.:format)                                                                        source_tags#update
#                                          DELETE /source_tags/:id(.:format)                                                                        source_tags#destroy
#                         warehouse_orders GET    /warehouse/orders(.:format)                                                                       warehouse/orders#index
#                                          POST   /warehouse/orders(.:format)                                                                       warehouse/orders#create
#                      new_warehouse_order GET    /warehouse/orders/new(.:format)                                                                   warehouse/orders#new
#                     edit_warehouse_order GET    /warehouse/orders/:id/edit(.:format)                                                              warehouse/orders#edit
#                          warehouse_order GET    /warehouse/orders/:id(.:format)                                                                   warehouse/orders#show
#                                          PATCH  /warehouse/orders/:id(.:format)                                                                   warehouse/orders#update
#                                          PUT    /warehouse/orders/:id(.:format)                                                                   warehouse/orders#update
#                                          DELETE /warehouse/orders/:id(.:format)                                                                   warehouse/orders#destroy
#                  warehouse_purpose_codes GET    /warehouse/purpose_codes(.:format)                                                                warehouse/purpose_codes#index
#                                          POST   /warehouse/purpose_codes(.:format)                                                                warehouse/purpose_codes#create
#               new_warehouse_purpose_code GET    /warehouse/purpose_codes/new(.:format)                                                            warehouse/purpose_codes#new
#              edit_warehouse_purpose_code GET    /warehouse/purpose_codes/:id/edit(.:format)                                                       warehouse/purpose_codes#edit
#                   warehouse_purpose_code GET    /warehouse/purpose_codes/:id(.:format)                                                            warehouse/purpose_codes#show
#                                          PATCH  /warehouse/purpose_codes/:id(.:format)                                                            warehouse/purpose_codes#update
#                                          PUT    /warehouse/purpose_codes/:id(.:format)                                                            warehouse/purpose_codes#update
#                                          DELETE /warehouse/purpose_codes/:id(.:format)                                                            warehouse/purpose_codes#destroy
#                           warehouse_skus GET    /warehouse/skus(.:format)                                                                         warehouse/skus#index
#                                          POST   /warehouse/skus(.:format)                                                                         warehouse/skus#create
#                        new_warehouse_sku GET    /warehouse/skus/new(.:format)                                                                     warehouse/skus#new
#                       edit_warehouse_sku GET    /warehouse/skus/:id/edit(.:format)                                                                warehouse/skus#edit
#                            warehouse_sku GET    /warehouse/skus/:id(.:format)                                                                     warehouse/skus#show
#                                          PATCH  /warehouse/skus/:id(.:format)                                                                     warehouse/skus#update
#                                          PUT    /warehouse/skus/:id(.:format)                                                                     warehouse/skus#update
#                                          DELETE /warehouse/skus/:id(.:format)                                                                     warehouse/skus#destroy
#                                    users GET    /users(.:format)                                                                                  users#index
#                                          POST   /users(.:format)                                                                                  users#create
#                                 new_user GET    /users/new(.:format)                                                                              users#new
#                                edit_user GET    /users/:id/edit(.:format)                                                                         users#edit
#                                     user GET    /users/:id(.:format)                                                                              users#show
#                                          PATCH  /users/:id(.:format)                                                                              users#update
#                                          PUT    /users/:id(.:format)                                                                              users#update
#                                          DELETE /users/:id(.:format)                                                                              users#destroy
#                                     root GET    /                                                                                                 static_pages#index
#                               slack_auth GET    /auth/slack(.:format)                                                                             sessions#new
#                      auth_slack_callback GET    /auth/slack/callback(.:format)                                                                    sessions#create
#                                  signout DELETE /signout(.:format)                                                                                sessions#destroy
#                       rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#                                    login GET    /login(.:format)                                                                                  static_pages#login
#         turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#         turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
#        turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#            rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#               rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#            rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#      rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#            rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#             rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#           rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                          POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#        new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#            rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
# new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#    rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#    rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
# rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                       rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                 rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                          GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#          rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                          GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                       rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                     rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create

class AdminConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin?
  end
end

Rails.application.routes.draw do
  scope path: "back_office" do
    get "/tags", to: "tags#index"
    get "/tags/:id", to: "tags#show", as: :tag_stats
    post "/tags/refresh", to: "tags#refresh", as: :refresh_tags
    resources :letters do
      member do
        post :generate_label
        post :buy_indicia
        post :mark_printed
        post :mark_mailed
        post :mark_received
        post :clear_label
        get :preview_template if Rails.env.development?
      end
    end
    namespace :letter do
      resources :batches do
        member do
          get "/map", to: "batches#map_fields", as: :map_fields
          post :set_mapping
          get "/process", to: "batches#process_form", as: :process_confirm
          post "/process", to: "batches#process_batch", as: :process
          post :mark_printed
          post :mark_mailed
          post :update_costs
        end
      end
      resources :queues do
        member do
          post :batch, as: :make_batch_from
        end
      end
    end
    resources :api_keys do
      member do
        get "/revoke", to: "api_keys#revoke_confirm", as: :revoke_confirm
        post :revoke
      end
    end

    namespace :admin do
      resources :addresses
      resources :return_addresses
      resources :source_tags
      resources :users

      namespace :warehouse do
        resources :templates
        resources :orders
        resources :skus
      end

      namespace :usps do
        resources :mailer_ids
        resources :payment_accounts
      end

      resources :common_tags

      root to: "users#index"
    end

    constraints AdminConstraint do
      mount GoodJob::Engine => "good_job"
      mount Blazer::Engine, at: "blazer"
      get "/impersonate/:id", to: "sessions#impersonate", as: :impersonate_user
    end
    get "/stop_impersonating", to: "sessions#stop_impersonating", as: :stop_impersonating

    namespace :usps do
      resources :indicia
      resources :payment_accounts
      resources :mailer_ids
    end
    resources :source_tags
    namespace :warehouse do
      resources :templates
      resources :orders do
        member do
          get :cancel
          post :cancel, to: "orders#confirm_cancel"
          post "send_to_warehouse"
        end
      end
      resources :batches do
        member do
          get "/map", to: "batches#map_fields", as: :map_fields
          post :set_mapping
          get "/process", to: "batches#process_form", as: :process_confirm
          post "/process", to: "batches#process_batch", as: :process
        end
      end
      resources :skus
    end
    resources :users
    resources :return_addresses do
      member do
        post :set_as_home
      end
    end
    root "static_pages#index"

    delete "signout", to: "sessions#destroy", as: :signout
    get "/login" => "static_pages#login"
  end

  get "/auth/slack", to: "sessions#new", as: :slack_auth
  get "/auth/slack/callback", to: "sessions#create"

  root "public/static_pages#root", as: :public_root

  get "/login" => "public/static_pages#login", as: :public_login
  post "/login" => "public/sessions#send_email", as: :send_email
  get "/login/:token", to: "public/sessions#login_code", as: :login_code
  delete "logout", to: "public/sessions#destroy", as: :public_logout
  get "/my_mail", to: "public/mail#index", as: :my_mail

  resources :leaderboards, module: :public, only: [] do
    collection do
      get "this_week"
      get "this_month"
      get "all_time"
    end
  end

  resources "letters", module: :public_, only: [:show] do
    member do
      post :mark_received, as: :public_mark_received
      post :mark_mailed, as: :public_mark_mailed
    end
  end

  get "/letters/:id", to: "public/letters#show", as: :public_letter
  get "/packages/:id", to: "public/packages#show", as: :public_package

  get "/impersonate", to: "public/impersonations#new", as: :public_impersonate_form
  post "/impersonate", to: "public/impersonations#create", as: :public_impersonate
  get "/stop_impersonating", to: "public/impersonations#stop_impersonating", as: :public_stop_impersonating

  get "/:public_id", to: "public/public_identifiable#show", constraints: { public_id: /(pkg|ltr)![^\/]+/ }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope :webhooks do
    namespace :usps do
      namespace :iv_mtr do
        post "", to: "webhook#ingest"
      end
    end
  end

  namespace :api do
    defaults format: :json do
      namespace :v1 do
        resource :user
        resources :letters
        resources :letter_queues do
          member do
            post "", to: "letter_queues#create_letter", as: :create_letter
          end
        end
      end
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
