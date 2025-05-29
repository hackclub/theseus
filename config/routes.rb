# == Route Map
#
#                                     Prefix Verb   URI Pattern                                                                                       Controller#Action
#                          lookup_public_ids POST   /back_office/public_ids/lookup(.:format)                                                          public_ids#lookup
#                                 public_ids GET    /back_office/public_ids(.:format)                                                                 public_ids#index
#                       inspect_iv_mtr_event GET    /back_office/inspect/iv_mtr_events/:id(.:format)                                                  inspect/iv_mtr_events#show
#                           inspect_indicium GET    /back_office/inspect/indicia/:id(.:format)                                                        inspect/indicia#show
#                                badge_tasks GET    /back_office/my/tasks/badge(.:format)                                                             tasks#badge
#                              refresh_tasks POST   /back_office/my/tasks/refresh(.:format)                                                           tasks#refresh
#                                      tasks GET    /back_office/my/tasks(.:format)                                                                   tasks#show
#                                       tags GET    /back_office/tags(.:format)                                                                       tags#index
#                                  tag_stats GET    /back_office/tags/:id(.:format)                                                                   tags#show
#                               refresh_tags POST   /back_office/tags/refresh(.:format)                                                               tags#refresh
#                      generate_label_letter POST   /back_office/letters/:id/generate_label(.:format)                                                 letters#generate_label
#                         buy_indicia_letter POST   /back_office/letters/:id/buy_indicia(.:format)                                                    letters#buy_indicia
#                        mark_printed_letter POST   /back_office/letters/:id/mark_printed(.:format)                                                   letters#mark_printed
#                         mark_mailed_letter POST   /back_office/letters/:id/mark_mailed(.:format)                                                    letters#mark_mailed
#                       mark_received_letter POST   /back_office/letters/:id/mark_received(.:format)                                                  letters#mark_received
#                         clear_label_letter POST   /back_office/letters/:id/clear_label(.:format)                                                    letters#clear_label
#                    preview_template_letter GET    /back_office/letters/:id/preview_template(.:format)                                               letters#preview_template
#                                    letters GET    /back_office/letters(.:format)                                                                    letters#index
#                                            POST   /back_office/letters(.:format)                                                                    letters#create
#                                 new_letter GET    /back_office/letters/new(.:format)                                                                letters#new
#                                edit_letter GET    /back_office/letters/:id/edit(.:format)                                                           letters#edit
#                                     letter GET    /back_office/letters/:id(.:format)                                                                letters#show
#                                            PATCH  /back_office/letters/:id(.:format)                                                                letters#update
#                                            PUT    /back_office/letters/:id(.:format)                                                                letters#update
#                                            DELETE /back_office/letters/:id(.:format)                                                                letters#destroy
#                    map_fields_letter_batch GET    /back_office/letter/batches/:id/map(.:format)                                                     letter/batches#map_fields
#                   set_mapping_letter_batch POST   /back_office/letter/batches/:id/set_mapping(.:format)                                             letter/batches#set_mapping
#               process_confirm_letter_batch GET    /back_office/letter/batches/:id/process(.:format)                                                 letter/batches#process_form
#                       process_letter_batch POST   /back_office/letter/batches/:id/process(.:format)                                                 letter/batches#process_batch
#                  mark_printed_letter_batch POST   /back_office/letter/batches/:id/mark_printed(.:format)                                            letter/batches#mark_printed
#                   mark_mailed_letter_batch POST   /back_office/letter/batches/:id/mark_mailed(.:format)                                             letter/batches#mark_mailed
#                  update_costs_letter_batch POST   /back_office/letter/batches/:id/update_costs(.:format)                                            letter/batches#update_costs
#               regenerate_form_letter_batch GET    /back_office/letter/batches/:id/regen(.:format)                                                   letter/batches#regenerate_form
#             regenerate_labels_letter_batch POST   /back_office/letter/batches/:id/regen(.:format)                                                   letter/batches#regenerate_labels
#                             letter_batches GET    /back_office/letter/batches(.:format)                                                             letter/batches#index
#                                            POST   /back_office/letter/batches(.:format)                                                             letter/batches#create
#                           new_letter_batch GET    /back_office/letter/batches/new(.:format)                                                         letter/batches#new
#                          edit_letter_batch GET    /back_office/letter/batches/:id/edit(.:format)                                                    letter/batches#edit
#                               letter_batch GET    /back_office/letter/batches/:id(.:format)                                                         letter/batches#show
#                                            PATCH  /back_office/letter/batches/:id(.:format)                                                         letter/batches#update
#                                            PUT    /back_office/letter/batches/:id(.:format)                                                         letter/batches#update
#                                            DELETE /back_office/letter/batches/:id(.:format)                                                         letter/batches#destroy
#               make_batch_from_letter_queue POST   /back_office/letter/queues/:id/batch(.:format)                                                    letter/queues#batch
#                              letter_queues GET    /back_office/letter/queues(.:format)                                                              letter/queues#index
#                                            POST   /back_office/letter/queues(.:format)                                                              letter/queues#create
#                           new_letter_queue GET    /back_office/letter/queues/new(.:format)                                                          letter/queues#new
#                          edit_letter_queue GET    /back_office/letter/queues/:id/edit(.:format)                                                     letter/queues#edit
#                               letter_queue GET    /back_office/letter/queues/:id(.:format)                                                          letter/queues#show
#                                            PATCH  /back_office/letter/queues/:id(.:format)                                                          letter/queues#update
#                                            PUT    /back_office/letter/queues/:id(.:format)                                                          letter/queues#update
#                                            DELETE /back_office/letter/queues/:id(.:format)                                                          letter/queues#destroy
#                      letter_instant_queues GET    /back_office/letter/instant_queues(.:format)                                                      letter/instant_queues#index
#                                            POST   /back_office/letter/instant_queues(.:format)                                                      letter/instant_queues#create
#                   new_letter_instant_queue GET    /back_office/letter/instant_queues/new(.:format)                                                  letter/instant_queues#new
#                  edit_letter_instant_queue GET    /back_office/letter/instant_queues/:id/edit(.:format)                                             letter/instant_queues#edit
#                       letter_instant_queue GET    /back_office/letter/instant_queues/:id(.:format)                                                  letter/instant_queues#show
#                                            PATCH  /back_office/letter/instant_queues/:id(.:format)                                                  letter/instant_queues#update
#                                            PUT    /back_office/letter/instant_queues/:id(.:format)                                                  letter/instant_queues#update
#                                            DELETE /back_office/letter/instant_queues/:id(.:format)                                                  letter/instant_queues#destroy
#                     revoke_confirm_api_key GET    /back_office/api_keys/:id/revoke(.:format)                                                        api_keys#revoke_confirm
#                             revoke_api_key POST   /back_office/api_keys/:id/revoke(.:format)                                                        api_keys#revoke
#                                   api_keys GET    /back_office/api_keys(.:format)                                                                   api_keys#index
#                                            POST   /back_office/api_keys(.:format)                                                                   api_keys#create
#                                new_api_key GET    /back_office/api_keys/new(.:format)                                                               api_keys#new
#                               edit_api_key GET    /back_office/api_keys/:id/edit(.:format)                                                          api_keys#edit
#                                    api_key GET    /back_office/api_keys/:id(.:format)                                                               api_keys#show
#                                            PATCH  /back_office/api_keys/:id(.:format)                                                               api_keys#update
#                                            PUT    /back_office/api_keys/:id(.:format)                                                               api_keys#update
#                                            DELETE /back_office/api_keys/:id(.:format)                                                               api_keys#destroy
#                            admin_addresses GET    /back_office/admin/addresses(.:format)                                                            admin/addresses#index
#                                            POST   /back_office/admin/addresses(.:format)                                                            admin/addresses#create
#                          new_admin_address GET    /back_office/admin/addresses/new(.:format)                                                        admin/addresses#new
#                         edit_admin_address GET    /back_office/admin/addresses/:id/edit(.:format)                                                   admin/addresses#edit
#                              admin_address GET    /back_office/admin/addresses/:id(.:format)                                                        admin/addresses#show
#                                            PATCH  /back_office/admin/addresses/:id(.:format)                                                        admin/addresses#update
#                                            PUT    /back_office/admin/addresses/:id(.:format)                                                        admin/addresses#update
#                                            DELETE /back_office/admin/addresses/:id(.:format)                                                        admin/addresses#destroy
#                     admin_return_addresses GET    /back_office/admin/return_addresses(.:format)                                                     admin/return_addresses#index
#                                            POST   /back_office/admin/return_addresses(.:format)                                                     admin/return_addresses#create
#                   new_admin_return_address GET    /back_office/admin/return_addresses/new(.:format)                                                 admin/return_addresses#new
#                  edit_admin_return_address GET    /back_office/admin/return_addresses/:id/edit(.:format)                                            admin/return_addresses#edit
#                       admin_return_address GET    /back_office/admin/return_addresses/:id(.:format)                                                 admin/return_addresses#show
#                                            PATCH  /back_office/admin/return_addresses/:id(.:format)                                                 admin/return_addresses#update
#                                            PUT    /back_office/admin/return_addresses/:id(.:format)                                                 admin/return_addresses#update
#                                            DELETE /back_office/admin/return_addresses/:id(.:format)                                                 admin/return_addresses#destroy
#                          admin_source_tags GET    /back_office/admin/source_tags(.:format)                                                          admin/source_tags#index
#                                            POST   /back_office/admin/source_tags(.:format)                                                          admin/source_tags#create
#                       new_admin_source_tag GET    /back_office/admin/source_tags/new(.:format)                                                      admin/source_tags#new
#                      edit_admin_source_tag GET    /back_office/admin/source_tags/:id/edit(.:format)                                                 admin/source_tags#edit
#                           admin_source_tag GET    /back_office/admin/source_tags/:id(.:format)                                                      admin/source_tags#show
#                                            PATCH  /back_office/admin/source_tags/:id(.:format)                                                      admin/source_tags#update
#                                            PUT    /back_office/admin/source_tags/:id(.:format)                                                      admin/source_tags#update
#                                            DELETE /back_office/admin/source_tags/:id(.:format)                                                      admin/source_tags#destroy
#                                admin_users GET    /back_office/admin/users(.:format)                                                                admin/users#index
#                                            POST   /back_office/admin/users(.:format)                                                                admin/users#create
#                             new_admin_user GET    /back_office/admin/users/new(.:format)                                                            admin/users#new
#                            edit_admin_user GET    /back_office/admin/users/:id/edit(.:format)                                                       admin/users#edit
#                                 admin_user GET    /back_office/admin/users/:id(.:format)                                                            admin/users#show
#                                            PATCH  /back_office/admin/users/:id(.:format)                                                            admin/users#update
#                                            PUT    /back_office/admin/users/:id(.:format)                                                            admin/users#update
#                                            DELETE /back_office/admin/users/:id(.:format)                                                            admin/users#destroy
#                  admin_warehouse_templates GET    /back_office/admin/warehouse/templates(.:format)                                                  admin/warehouse/templates#index
#                                            POST   /back_office/admin/warehouse/templates(.:format)                                                  admin/warehouse/templates#create
#               new_admin_warehouse_template GET    /back_office/admin/warehouse/templates/new(.:format)                                              admin/warehouse/templates#new
#              edit_admin_warehouse_template GET    /back_office/admin/warehouse/templates/:id/edit(.:format)                                         admin/warehouse/templates#edit
#                   admin_warehouse_template GET    /back_office/admin/warehouse/templates/:id(.:format)                                              admin/warehouse/templates#show
#                                            PATCH  /back_office/admin/warehouse/templates/:id(.:format)                                              admin/warehouse/templates#update
#                                            PUT    /back_office/admin/warehouse/templates/:id(.:format)                                              admin/warehouse/templates#update
#                                            DELETE /back_office/admin/warehouse/templates/:id(.:format)                                              admin/warehouse/templates#destroy
#                     admin_warehouse_orders GET    /back_office/admin/warehouse/orders(.:format)                                                     admin/warehouse/orders#index
#                                            POST   /back_office/admin/warehouse/orders(.:format)                                                     admin/warehouse/orders#create
#                  new_admin_warehouse_order GET    /back_office/admin/warehouse/orders/new(.:format)                                                 admin/warehouse/orders#new
#                 edit_admin_warehouse_order GET    /back_office/admin/warehouse/orders/:id/edit(.:format)                                            admin/warehouse/orders#edit
#                      admin_warehouse_order GET    /back_office/admin/warehouse/orders/:id(.:format)                                                 admin/warehouse/orders#show
#                                            PATCH  /back_office/admin/warehouse/orders/:id(.:format)                                                 admin/warehouse/orders#update
#                                            PUT    /back_office/admin/warehouse/orders/:id(.:format)                                                 admin/warehouse/orders#update
#                                            DELETE /back_office/admin/warehouse/orders/:id(.:format)                                                 admin/warehouse/orders#destroy
#                       admin_warehouse_skus GET    /back_office/admin/warehouse/skus(.:format)                                                       admin/warehouse/skus#index
#                                            POST   /back_office/admin/warehouse/skus(.:format)                                                       admin/warehouse/skus#create
#                    new_admin_warehouse_sku GET    /back_office/admin/warehouse/skus/new(.:format)                                                   admin/warehouse/skus#new
#                   edit_admin_warehouse_sku GET    /back_office/admin/warehouse/skus/:id/edit(.:format)                                              admin/warehouse/skus#edit
#                        admin_warehouse_sku GET    /back_office/admin/warehouse/skus/:id(.:format)                                                   admin/warehouse/skus#show
#                                            PATCH  /back_office/admin/warehouse/skus/:id(.:format)                                                   admin/warehouse/skus#update
#                                            PUT    /back_office/admin/warehouse/skus/:id(.:format)                                                   admin/warehouse/skus#update
#                                            DELETE /back_office/admin/warehouse/skus/:id(.:format)                                                   admin/warehouse/skus#destroy
#                      admin_usps_mailer_ids GET    /back_office/admin/usps/mailer_ids(.:format)                                                      admin/usps/mailer_ids#index
#                                            POST   /back_office/admin/usps/mailer_ids(.:format)                                                      admin/usps/mailer_ids#create
#                   new_admin_usps_mailer_id GET    /back_office/admin/usps/mailer_ids/new(.:format)                                                  admin/usps/mailer_ids#new
#                  edit_admin_usps_mailer_id GET    /back_office/admin/usps/mailer_ids/:id/edit(.:format)                                             admin/usps/mailer_ids#edit
#                       admin_usps_mailer_id GET    /back_office/admin/usps/mailer_ids/:id(.:format)                                                  admin/usps/mailer_ids#show
#                                            PATCH  /back_office/admin/usps/mailer_ids/:id(.:format)                                                  admin/usps/mailer_ids#update
#                                            PUT    /back_office/admin/usps/mailer_ids/:id(.:format)                                                  admin/usps/mailer_ids#update
#                                            DELETE /back_office/admin/usps/mailer_ids/:id(.:format)                                                  admin/usps/mailer_ids#destroy
#                admin_usps_payment_accounts GET    /back_office/admin/usps/payment_accounts(.:format)                                                admin/usps/payment_accounts#index
#                                            POST   /back_office/admin/usps/payment_accounts(.:format)                                                admin/usps/payment_accounts#create
#             new_admin_usps_payment_account GET    /back_office/admin/usps/payment_accounts/new(.:format)                                            admin/usps/payment_accounts#new
#            edit_admin_usps_payment_account GET    /back_office/admin/usps/payment_accounts/:id/edit(.:format)                                       admin/usps/payment_accounts#edit
#                 admin_usps_payment_account GET    /back_office/admin/usps/payment_accounts/:id(.:format)                                            admin/usps/payment_accounts#show
#                                            PATCH  /back_office/admin/usps/payment_accounts/:id(.:format)                                            admin/usps/payment_accounts#update
#                                            PUT    /back_office/admin/usps/payment_accounts/:id(.:format)                                            admin/usps/payment_accounts#update
#                                            DELETE /back_office/admin/usps/payment_accounts/:id(.:format)                                            admin/usps/payment_accounts#destroy
#                          admin_common_tags GET    /back_office/admin/common_tags(.:format)                                                          admin/common_tags#index
#                                            POST   /back_office/admin/common_tags(.:format)                                                          admin/common_tags#create
#                       new_admin_common_tag GET    /back_office/admin/common_tags/new(.:format)                                                      admin/common_tags#new
#                      edit_admin_common_tag GET    /back_office/admin/common_tags/:id/edit(.:format)                                                 admin/common_tags#edit
#                           admin_common_tag GET    /back_office/admin/common_tags/:id(.:format)                                                      admin/common_tags#show
#                                            PATCH  /back_office/admin/common_tags/:id(.:format)                                                      admin/common_tags#update
#                                            PUT    /back_office/admin/common_tags/:id(.:format)                                                      admin/common_tags#update
#                                            DELETE /back_office/admin/common_tags/:id(.:format)                                                      admin/common_tags#destroy
#                                 admin_root GET    /back_office/admin(.:format)                                                                      admin/users#index
#                                   good_job        /back_office/good_job                                                                             GoodJob::Engine
#                                     blazer        /back_office/blazer                                                                               Blazer::Engine
#                           impersonate_user GET    /back_office/impersonate/:id(.:format)                                                            sessions#impersonate
#                         stop_impersonating GET    /back_office/stop_impersonating(.:format)                                                         sessions#stop_impersonating
#                               usps_indicia GET    /back_office/usps/indicia(.:format)                                                               usps/indicia#index
#                                            POST   /back_office/usps/indicia(.:format)                                                               usps/indicia#create
#                          new_usps_indicium GET    /back_office/usps/indicia/new(.:format)                                                           usps/indicia#new
#                         edit_usps_indicium GET    /back_office/usps/indicia/:id/edit(.:format)                                                      usps/indicia#edit
#                              usps_indicium GET    /back_office/usps/indicia/:id(.:format)                                                           usps/indicia#show
#                                            PATCH  /back_office/usps/indicia/:id(.:format)                                                           usps/indicia#update
#                                            PUT    /back_office/usps/indicia/:id(.:format)                                                           usps/indicia#update
#                                            DELETE /back_office/usps/indicia/:id(.:format)                                                           usps/indicia#destroy
#                      usps_payment_accounts GET    /back_office/usps/payment_accounts(.:format)                                                      usps/payment_accounts#index
#                                            POST   /back_office/usps/payment_accounts(.:format)                                                      usps/payment_accounts#create
#                   new_usps_payment_account GET    /back_office/usps/payment_accounts/new(.:format)                                                  usps/payment_accounts#new
#                  edit_usps_payment_account GET    /back_office/usps/payment_accounts/:id/edit(.:format)                                             usps/payment_accounts#edit
#                       usps_payment_account GET    /back_office/usps/payment_accounts/:id(.:format)                                                  usps/payment_accounts#show
#                                            PATCH  /back_office/usps/payment_accounts/:id(.:format)                                                  usps/payment_accounts#update
#                                            PUT    /back_office/usps/payment_accounts/:id(.:format)                                                  usps/payment_accounts#update
#                                            DELETE /back_office/usps/payment_accounts/:id(.:format)                                                  usps/payment_accounts#destroy
#                            usps_mailer_ids GET    /back_office/usps/mailer_ids(.:format)                                                            usps/mailer_ids#index
#                                            POST   /back_office/usps/mailer_ids(.:format)                                                            usps/mailer_ids#create
#                         new_usps_mailer_id GET    /back_office/usps/mailer_ids/new(.:format)                                                        usps/mailer_ids#new
#                        edit_usps_mailer_id GET    /back_office/usps/mailer_ids/:id/edit(.:format)                                                   usps/mailer_ids#edit
#                             usps_mailer_id GET    /back_office/usps/mailer_ids/:id(.:format)                                                        usps/mailer_ids#show
#                                            PATCH  /back_office/usps/mailer_ids/:id(.:format)                                                        usps/mailer_ids#update
#                                            PUT    /back_office/usps/mailer_ids/:id(.:format)                                                        usps/mailer_ids#update
#                                            DELETE /back_office/usps/mailer_ids/:id(.:format)                                                        usps/mailer_ids#destroy
#                                source_tags GET    /back_office/source_tags(.:format)                                                                source_tags#index
#                                            POST   /back_office/source_tags(.:format)                                                                source_tags#create
#                             new_source_tag GET    /back_office/source_tags/new(.:format)                                                            source_tags#new
#                            edit_source_tag GET    /back_office/source_tags/:id/edit(.:format)                                                       source_tags#edit
#                                 source_tag GET    /back_office/source_tags/:id(.:format)                                                            source_tags#show
#                                            PATCH  /back_office/source_tags/:id(.:format)                                                            source_tags#update
#                                            PUT    /back_office/source_tags/:id(.:format)                                                            source_tags#update
#                                            DELETE /back_office/source_tags/:id(.:format)                                                            source_tags#destroy
#                        warehouse_templates GET    /back_office/warehouse/templates(.:format)                                                        warehouse/templates#index
#                                            POST   /back_office/warehouse/templates(.:format)                                                        warehouse/templates#create
#                     new_warehouse_template GET    /back_office/warehouse/templates/new(.:format)                                                    warehouse/templates#new
#                    edit_warehouse_template GET    /back_office/warehouse/templates/:id/edit(.:format)                                               warehouse/templates#edit
#                         warehouse_template GET    /back_office/warehouse/templates/:id(.:format)                                                    warehouse/templates#show
#                                            PATCH  /back_office/warehouse/templates/:id(.:format)                                                    warehouse/templates#update
#                                            PUT    /back_office/warehouse/templates/:id(.:format)                                                    warehouse/templates#update
#                                            DELETE /back_office/warehouse/templates/:id(.:format)                                                    warehouse/templates#destroy
#                     cancel_warehouse_order GET    /back_office/warehouse/orders/:id/cancel(.:format)                                                warehouse/orders#cancel
#                                            POST   /back_office/warehouse/orders/:id/cancel(.:format)                                                warehouse/orders#confirm_cancel
#          send_to_warehouse_warehouse_order POST   /back_office/warehouse/orders/:id/send_to_warehouse(.:format)                                     warehouse/orders#send_to_warehouse
#                           warehouse_orders GET    /back_office/warehouse/orders(.:format)                                                           warehouse/orders#index
#                                            POST   /back_office/warehouse/orders(.:format)                                                           warehouse/orders#create
#                        new_warehouse_order GET    /back_office/warehouse/orders/new(.:format)                                                       warehouse/orders#new
#                       edit_warehouse_order GET    /back_office/warehouse/orders/:id/edit(.:format)                                                  warehouse/orders#edit
#                            warehouse_order GET    /back_office/warehouse/orders/:id(.:format)                                                       warehouse/orders#show
#                                            PATCH  /back_office/warehouse/orders/:id(.:format)                                                       warehouse/orders#update
#                                            PUT    /back_office/warehouse/orders/:id(.:format)                                                       warehouse/orders#update
#                                            DELETE /back_office/warehouse/orders/:id(.:format)                                                       warehouse/orders#destroy
#                 map_fields_warehouse_batch GET    /back_office/warehouse/batches/:id/map(.:format)                                                  warehouse/batches#map_fields
#                set_mapping_warehouse_batch POST   /back_office/warehouse/batches/:id/set_mapping(.:format)                                          warehouse/batches#set_mapping
#            process_confirm_warehouse_batch GET    /back_office/warehouse/batches/:id/process(.:format)                                              warehouse/batches#process_form
#                    process_warehouse_batch POST   /back_office/warehouse/batches/:id/process(.:format)                                              warehouse/batches#process_batch
#                          warehouse_batches GET    /back_office/warehouse/batches(.:format)                                                          warehouse/batches#index
#                                            POST   /back_office/warehouse/batches(.:format)                                                          warehouse/batches#create
#                        new_warehouse_batch GET    /back_office/warehouse/batches/new(.:format)                                                      warehouse/batches#new
#                       edit_warehouse_batch GET    /back_office/warehouse/batches/:id/edit(.:format)                                                 warehouse/batches#edit
#                            warehouse_batch GET    /back_office/warehouse/batches/:id(.:format)                                                      warehouse/batches#show
#                                            PATCH  /back_office/warehouse/batches/:id(.:format)                                                      warehouse/batches#update
#                                            PUT    /back_office/warehouse/batches/:id(.:format)                                                      warehouse/batches#update
#                                            DELETE /back_office/warehouse/batches/:id(.:format)                                                      warehouse/batches#destroy
#                             warehouse_skus GET    /back_office/warehouse/skus(.:format)                                                             warehouse/skus#index
#                                            POST   /back_office/warehouse/skus(.:format)                                                             warehouse/skus#create
#                          new_warehouse_sku GET    /back_office/warehouse/skus/new(.:format)                                                         warehouse/skus#new
#                         edit_warehouse_sku GET    /back_office/warehouse/skus/:id/edit(.:format)                                                    warehouse/skus#edit
#                              warehouse_sku GET    /back_office/warehouse/skus/:id(.:format)                                                         warehouse/skus#show
#                                            PATCH  /back_office/warehouse/skus/:id(.:format)                                                         warehouse/skus#update
#                                            PUT    /back_office/warehouse/skus/:id(.:format)                                                         warehouse/skus#update
#                                            DELETE /back_office/warehouse/skus/:id(.:format)                                                         warehouse/skus#destroy
#                                      users GET    /back_office/users(.:format)                                                                      users#index
#                                            POST   /back_office/users(.:format)                                                                      users#create
#                                   new_user GET    /back_office/users/new(.:format)                                                                  users#new
#                                  edit_user GET    /back_office/users/:id/edit(.:format)                                                             users#edit
#                                       user GET    /back_office/users/:id(.:format)                                                                  users#show
#                                            PATCH  /back_office/users/:id(.:format)                                                                  users#update
#                                            PUT    /back_office/users/:id(.:format)                                                                  users#update
#                                            DELETE /back_office/users/:id(.:format)                                                                  users#destroy
#                 set_as_home_return_address POST   /back_office/return_addresses/:id/set_as_home(.:format)                                           return_addresses#set_as_home
#                           return_addresses GET    /back_office/return_addresses(.:format)                                                           return_addresses#index
#                                            POST   /back_office/return_addresses(.:format)                                                           return_addresses#create
#                         new_return_address GET    /back_office/return_addresses/new(.:format)                                                       return_addresses#new
#                        edit_return_address GET    /back_office/return_addresses/:id/edit(.:format)                                                  return_addresses#edit
#                             return_address GET    /back_office/return_addresses/:id(.:format)                                                       return_addresses#show
#                                            PATCH  /back_office/return_addresses/:id(.:format)                                                       return_addresses#update
#                                            PUT    /back_office/return_addresses/:id(.:format)                                                       return_addresses#update
#                                            DELETE /back_office/return_addresses/:id(.:format)                                                       return_addresses#destroy
#                                       root GET    /back_office(.:format)                                                                            static_pages#index
#                                    signout DELETE /back_office/signout(.:format)                                                                    sessions#destroy
#                                      login GET    /back_office/login(.:format)                                                                      static_pages#login
#                                 slack_auth GET    /auth/slack(.:format)                                                                             sessions#new
#                        auth_slack_callback GET    /auth/slack/callback(.:format)                                                                    sessions#create
#                                public_root GET    /                                                                                                 public/static_pages#root
#                               public_login GET    /login(.:format)                                                                                  public/static_pages#login
#                                 send_email POST   /login(.:format)                                                                                  public/sessions#send_email
#                                 login_code GET    /login/:token(.:format)                                                                           public/sessions#login_code
#                              public_logout DELETE /logout(.:format)                                                                                 public/sessions#destroy
#                                    my_mail GET    /my/mail(.:format)                                                                                public/mail#index
#              revoke_confirm_public_api_key GET    /my/api_keys/:id/revoke(.:format)                                                                 public/api_keys#revoke_confirm
#                      revoke_public_api_key POST   /my/api_keys/:id/revoke(.:format)                                                                 public/api_keys#revoke
#                            public_api_keys GET    /my/api_keys(.:format)                                                                            public/api_keys#index
#                                            POST   /my/api_keys(.:format)                                                                            public/api_keys#create
#                         new_public_api_key GET    /my/api_keys/new(.:format)                                                                        public/api_keys#new
#                             public_api_key GET    /my/api_keys/:id(.:format)                                                                        public/api_keys#show
#                     this_week_leaderboards GET    /leaderboards/this_week(.:format)                                                                 public/leaderboards#this_week
#                    this_month_leaderboards GET    /leaderboards/this_month(.:format)                                                                public/leaderboards#this_month
#                      all_time_leaderboards GET    /leaderboards/all_time(.:format)                                                                  public/leaderboards#all_time
#                public_mark_received_letter POST   /letters/:id/mark_received(.:format)                                                              public_/letters#mark_received
#                  public_mark_mailed_letter POST   /letters/:id/mark_mailed(.:format)                                                                public_/letters#mark_mailed
#                                            GET    /letters/:id(.:format)                                                                            public_/letters#show
#                                   show_lsv GET    /lsv/:slug/:id(.:format)                                                                          public/lsv#show
#                              public_letter GET    /letters/:id(.:format)                                                                            public/letters#show
#                             public_package GET    /packages/:id(.:format)                                                                           public/packages#show
#                    public_impersonate_form GET    /impersonate(.:format)                                                                            public/impersonations#new
#                         public_impersonate POST   /impersonate(.:format)                                                                            public/impersonations#create
#                  public_stop_impersonating GET    /stop_impersonating(.:format)                                                                     public/impersonations#stop_impersonating
#                                            GET    /:public_id(.:format)                                                                             public/public_identifiable#show {:public_id=>/(pkg|ltr)![^\/]+/}
#                               cert_qz_tray GET    /qz_tray/cert(.:format)                                                                           qz_trays#cert
#                           settings_qz_tray GET    /qz_tray/settings(.:format)                                                                       qz_trays#settings
#                               sign_qz_tray POST   /qz_tray/sign(.:format)                                                                           qz_trays#sign
#                         test_print_qz_tray GET    /qz_tray/test_print(.:format)                                                                     qz_trays#test_print
#                         rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#                                usps_iv_mtr POST   /webhooks/usps/iv_mtr(.:format)                                                                   usps/iv_mtr/webhook#ingest
#                               public_v1_me GET    /api/public/v1/me(.:format)                                                                       public/api/v1/users#me {:format=>:json}
#                          public_v1_letters GET    /api/public/v1/letters(.:format)                                                                  public/api/v1/letters#index {:format=>:json}
#                           public_v1_letter GET    /api/public/v1/letters/:id(.:format)                                                              public/api/v1/letters#show {:format=>:json}
#                         public_v1_packages GET    /api/public/v1/packages(.:format)                                                                 public/api/v1/packages#index {:format=>:json}
#                          public_v1_package GET    /api/public/v1/packages/:id(.:format)                                                             public/api/v1/packages#show {:format=>:json}
#                       public_v1_mail_index GET    /api/public/v1/mail(.:format)                                                                     public/api/v1/mail#index {:format=>:json}
#                        public_v1_lsv_index GET    /api/public/v1/lsv(.:format)                                                                      public/api/v1/lsv#index {:format=>:json}
#                              public_v1_lsv GET    /api/public/v1/lsv/:slug/:id(.:format)                                                            public/api/v1/lsv#show {:format=>:json}
#                                  api_v1_me GET    /api/public/v1/me(.:format)                                                                       api/public/api/v1/users#me {:format=>:json}
#                            new_api_v1_user GET    /api/v1/user/new(.:format)                                                                        api/v1/users#new {:format=>:json}
#                           edit_api_v1_user GET    /api/v1/user/edit(.:format)                                                                       api/v1/users#edit {:format=>:json}
#                                api_v1_user GET    /api/v1/user(.:format)                                                                            api/v1/users#show {:format=>:json}
#                                            PATCH  /api/v1/user(.:format)                                                                            api/v1/users#update {:format=>:json}
#                                            PUT    /api/v1/user(.:format)                                                                            api/v1/users#update {:format=>:json}
#                                            DELETE /api/v1/user(.:format)                                                                            api/v1/users#destroy {:format=>:json}
#                                            POST   /api/v1/user(.:format)                                                                            api/v1/users#create {:format=>:json}
#                 mark_printed_api_v1_letter POST   /api/v1/letters/:id/mark_printed(.:format)                                                        api/v1/letters#mark_printed {:format=>:json}
#                             api_v1_letters GET    /api/v1/letters(.:format)                                                                         api/v1/letters#index {:format=>:json}
#                                            POST   /api/v1/letters(.:format)                                                                         api/v1/letters#create {:format=>:json}
#                          new_api_v1_letter GET    /api/v1/letters/new(.:format)                                                                     api/v1/letters#new {:format=>:json}
#                         edit_api_v1_letter GET    /api/v1/letters/:id/edit(.:format)                                                                api/v1/letters#edit {:format=>:json}
#                              api_v1_letter GET    /api/v1/letters/:id(.:format)                                                                     api/v1/letters#show {:format=>:json}
#                                            PATCH  /api/v1/letters/:id(.:format)                                                                     api/v1/letters#update {:format=>:json}
#                                            PUT    /api/v1/letters/:id(.:format)                                                                     api/v1/letters#update {:format=>:json}
#                                            DELETE /api/v1/letters/:id(.:format)                                                                     api/v1/letters#destroy {:format=>:json}
# create_instant_letter_api_v1_letter_queues POST   /api/v1/letter_queues/instant/:id(.:format)                                                       api/v1/letter_queues#create_instant_letter {:format=>:json}
#           show_queued_api_v1_letter_queues GET    /api/v1/letter_queues/instant/:id/queued(.:format)                                                api/v1/letter_queues#queued {:format=>:json}
#                                            POST   /api/v1/letter_queues/:id(.:format)                                                               api/v1/letter_queues#create_letter {:format=>:json}
#                       api_v1_letter_queues GET    /api/v1/letter_queues(.:format)                                                                   api/v1/letter_queues#index {:format=>:json}
#                                            POST   /api/v1/letter_queues(.:format)                                                                   api/v1/letter_queues#create {:format=>:json}
#                        api_v1_letter_queue GET    /api/v1/letter_queues/:id(.:format)                                                               api/v1/letter_queues#show {:format=>:json}
#                                            PATCH  /api/v1/letter_queues/:id(.:format)                                                               api/v1/letter_queues#update {:format=>:json}
#                                            PUT    /api/v1/letter_queues/:id(.:format)                                                               api/v1/letter_queues#update {:format=>:json}
#                                            DELETE /api/v1/letter_queues/:id(.:format)                                                               api/v1/letter_queues#destroy {:format=>:json}
#                        cert_api_v1_qz_tray GET    /api/v1/qz_tray/cert(.:format)                                                                    api/v1/qz_trays#cert {:format=>:json}
#                        sign_api_v1_qz_tray POST   /api/v1/qz_tray/sign(.:format)                                                                    api/v1/qz_trays#sign {:format=>:json}
#                                api_v1_tags GET    /api/v1/tags(.:format)                                                                            api/v1/tags#index {:format=>:json}
#                                 api_v1_tag GET    /api/v1/tags/:id(.:format)                                                                        api/v1/tags#show {:format=>:json}
#                          letter_opener_web        /letter_opener                                                                                    LetterOpenerWeb::Engine
#           turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#           turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
#          turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#              rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#                 rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#              rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#        rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#              rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#               rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#             rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                            POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#          new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#              rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
#   new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#      rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#      rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
#   rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                         rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                   rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                            GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                  rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#            rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                            GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                         rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                  update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                       rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create
#
# Routes for GoodJob::Engine:
#                root GET    /                                         good_job/jobs#redirect_to_index
#    mass_update_jobs GET    /jobs/mass_update(.:format)               redirect(301, path: jobs)
#                     PUT    /jobs/mass_update(.:format)               good_job/jobs#mass_update
#         discard_job PUT    /jobs/:id/discard(.:format)               good_job/jobs#discard
#   force_discard_job PUT    /jobs/:id/force_discard(.:format)         good_job/jobs#force_discard
#      reschedule_job PUT    /jobs/:id/reschedule(.:format)            good_job/jobs#reschedule
#           retry_job PUT    /jobs/:id/retry(.:format)                 good_job/jobs#retry
#                jobs GET    /jobs(.:format)                           good_job/jobs#index
#                 job GET    /jobs/:id(.:format)                       good_job/jobs#show
#                     DELETE /jobs/:id(.:format)                       good_job/jobs#destroy
# metrics_primary_nav GET    /jobs/metrics/primary_nav(.:format)       good_job/metrics#primary_nav
#  metrics_job_status GET    /jobs/metrics/job_status(.:format)        good_job/metrics#job_status
#         retry_batch PUT    /batches/:id/retry(.:format)              good_job/batches#retry
#             batches GET    /batches(.:format)                        good_job/batches#index
#               batch GET    /batches/:id(.:format)                    good_job/batches#show
#  enqueue_cron_entry POST   /cron_entries/:cron_key/enqueue(.:format) good_job/cron_entries#enqueue
#   enable_cron_entry PUT    /cron_entries/:cron_key/enable(.:format)  good_job/cron_entries#enable
#  disable_cron_entry PUT    /cron_entries/:cron_key/disable(.:format) good_job/cron_entries#disable
#        cron_entries GET    /cron_entries(.:format)                   good_job/cron_entries#index
#          cron_entry GET    /cron_entries/:cron_key(.:format)         good_job/cron_entries#show
#           processes GET    /processes(.:format)                      good_job/processes#index
#   performance_index GET    /performance(.:format)                    good_job/performance#index
#         performance GET    /performance/:id(.:format)                good_job/performance#show
#              pauses POST   /pauses(.:format)                         good_job/pauses#create
#                     DELETE /pauses(.:format)                         good_job/pauses#destroy
#                     GET    /pauses(.:format)                         good_job/pauses#index
#       cleaner_index GET    /cleaner(.:format)                        good_job/cleaner#index
#     frontend_module GET    /frontend/modules/:version/:id(.:format)  good_job/frontends#module {:version=>"4-9-3", :format=>"js"}
#     frontend_static GET    /frontend/static/:version/:id(.:format)   good_job/frontends#static {:version=>"4-9-3"}
#
# Routes for Blazer::Engine:
#       run_queries POST   /queries/run(.:format)            blazer/queries#run
#    cancel_queries POST   /queries/cancel(.:format)         blazer/queries#cancel
#     refresh_query POST   /queries/:id/refresh(.:format)    blazer/queries#refresh
#    tables_queries GET    /queries/tables(.:format)         blazer/queries#tables
#    schema_queries GET    /queries/schema(.:format)         blazer/queries#schema
#      docs_queries GET    /queries/docs(.:format)           blazer/queries#docs
#           queries GET    /queries(.:format)                blazer/queries#index
#                   POST   /queries(.:format)                blazer/queries#create
#         new_query GET    /queries/new(.:format)            blazer/queries#new
#        edit_query GET    /queries/:id/edit(.:format)       blazer/queries#edit
#             query GET    /queries/:id(.:format)            blazer/queries#show
#                   PATCH  /queries/:id(.:format)            blazer/queries#update
#                   PUT    /queries/:id(.:format)            blazer/queries#update
#                   DELETE /queries/:id(.:format)            blazer/queries#destroy
#         run_check GET    /checks/:id/run(.:format)         blazer/checks#run
#            checks GET    /checks(.:format)                 blazer/checks#index
#                   POST   /checks(.:format)                 blazer/checks#create
#         new_check GET    /checks/new(.:format)             blazer/checks#new
#        edit_check GET    /checks/:id/edit(.:format)        blazer/checks#edit
#             check PATCH  /checks/:id(.:format)             blazer/checks#update
#                   PUT    /checks/:id(.:format)             blazer/checks#update
#                   DELETE /checks/:id(.:format)             blazer/checks#destroy
# refresh_dashboard POST   /dashboards/:id/refresh(.:format) blazer/dashboards#refresh
#        dashboards POST   /dashboards(.:format)             blazer/dashboards#create
#     new_dashboard GET    /dashboards/new(.:format)         blazer/dashboards#new
#    edit_dashboard GET    /dashboards/:id/edit(.:format)    blazer/dashboards#edit
#         dashboard GET    /dashboards/:id(.:format)         blazer/dashboards#show
#                   PATCH  /dashboards/:id(.:format)         blazer/dashboards#update
#                   PUT    /dashboards/:id(.:format)         blazer/dashboards#update
#                   DELETE /dashboards/:id(.:format)         blazer/dashboards#destroy
#              root GET    /                                 blazer/queries#home
#
# Routes for LetterOpenerWeb::Engine:
#       letters GET  /                                letter_opener_web/letters#index
# clear_letters POST /clear(.:format)                 letter_opener_web/letters#clear
#        letter GET  /:id(/:style)(.:format)          letter_opener_web/letters#show
# delete_letter POST /:id/delete(.:format)            letter_opener_web/letters#destroy
#               GET  /:id/attachments/:file(.:format) letter_opener_web/letters#attachment {:file=>/[^\/]+/}

class AdminConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin?
  end
end

Rails.application.routes.draw do
  get "customs_receipts/index"
  get "customs_receipts/show"
  scope path: "back_office" do
    resources :public_ids, only: [:index] do
      collection do
        post :lookup
      end
    end

    namespace :inspect do
      resources :iv_mtr_events, only: [:show]
      resources :indicia, only: [:show]
    end
    scope :my do
      resource :tasks, only: %i(show) do
        get :badge
        post :refresh
      end
    end
    get "/tags", to: "tags#index"
    get "/tags/:id", to: "tags#show", as: :tag_stats
    post "/tags/refresh", to: "tags#refresh", as: :refresh_tags
    resources :customs_receipts, only: [:index] do
      collection do
        get :generate
      end
    end
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
          get :regen, to: "batches#regenerate_form", as: :regenerate_form
          post :regen, to: "batches#regenerate_labels", as: :regenerate_labels
        end
      end
      resources :queues do
        collection do
          post :mark_printed_instants_mailed
        end
        member do
          post :batch, as: :make_batch_from
        end
      end
      resources :instant_queues, controller: "instant_queues"
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

  scope :my do
    get "/mail", to: "public/mail#index", as: :my_mail
    resources :api_keys, module: :public, only: [:index, :new, :create, :show], as: :public_api_keys do
      member do
        get "/revoke", to: "api_keys#revoke_confirm", as: :revoke_confirm
        post :revoke
      end
    end
  end

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

  resource :map, only: [:show], module: :public

  get "/lsv/:slug/:id", to: "public/lsv#show", as: :show_lsv
  get "/lsv/msr/:id/customs_receipt", to: "public/lsv#customs_receipt", as: :msr_customs_receipt
  post "/lsv/msr/:id/customs_receipt", to: "public/lsv#generate_customs_receipt", as: :msr_generate_customs_receipt

  get "/packages/:id/customs_receipt", to: "public/packages#customs_receipt", as: :package_customs_receipt
  post "/packages/:id/customs_receipt", to: "public/packages#generate_customs_receipt", as: :package_generate_customs_receipt

  get "/letters/:id", to: "public/letters#show", as: :public_letter
  get "/packages/:id", to: "public/packages#show", as: :public_package

  get "/impersonate", to: "public/impersonations#new", as: :public_impersonate_form
  post "/impersonate", to: "public/impersonations#create", as: :public_impersonate
  get "/stop_impersonating", to: "public/impersonations#stop_impersonating", as: :public_stop_impersonating

  get "/:public_id", to: "public/public_identifiable#show", constraints: { public_id: /(pkg|ltr)![^\/]+/ }

  resource :qz_tray, only: [] do
    get :cert
    get :settings
    post :sign
    get :test_print
  end
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

  scope :api do
    defaults format: :json do
      namespace :public do
        scope "", module: :api do
          namespace :v1 do
            get :me, to: "users#me"
            resources :letters, only: [:index, :show]
            resources :packages, only: [:index, :show]
            resources :mail, only: [:index]
            resources :lsv, only: [:index]
            get "/lsv/:slug/:id", to: "lsv#show", as: :lsv
          end
        end
      end
    end
  end
  namespace :api do
    defaults format: :json do
      scope :public, module: :public do
        scope "", module: :api do
          namespace :v1 do
            get :me, to: "users#me"
          end
        end
      end
      namespace :v1 do
        resource :user
        resources :letters do
          member do
            post :mark_printed
          end
        end
        resources :letter_queues, only: [:index, :show, :create, :update, :destroy] do
          collection do
            post "instant/:id", to: "letter_queues#create_instant_letter", as: :create_instant_letter
            get "instant/:id/queued", to: "letter_queues#queued", as: :show_queued
          end
          member do
            post "", to: "letter_queues#create_letter"
          end
        end
        resource :qz_tray, only: [] do
          get :cert
          post :sign
        end
        resources :tags, only: [:index, :show] do
          member do
            get :letters
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
