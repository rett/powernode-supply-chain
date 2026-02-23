# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :supply_chain do
        # SBOM Management
        resources :sboms do
          member do
            get :components
            get :vulnerabilities
            post :export
            get :compliance_status
            post :correlate_vulnerabilities
            post :calculate_risk
          end

          collection do
            get :statistics
          end

          resources :components, only: [:index, :show] do
            member do
              get :vulnerabilities
            end
          end

          resources :vulnerabilities, only: [:index, :show, :update] do
            member do
              post :suppress
              post :unsuppress
              post :mark_false_positive
            end
          end

          resources :diffs, only: [:index, :show, :create]
        end

        # Vulnerability Feeds
        resources :vulnerability_feeds, only: [:index, :show] do
          member do
            post :sync
          end
          collection do
            post :sync_all
          end
        end

        # Remediation Plans
        resources :remediation_plans do
          member do
            post :generate_pr
            post :approve
            post :reject
            post :execute
          end
        end

        # Attestations (SLSA)
        resources :attestations do
          member do
            post :verify
            post :sign
            post :record_to_rekor
            get :verification_logs
          end
          collection do
            get :statistics
          end
        end

        # Build Provenance
        resources :build_provenance, only: [:index, :show] do
          member do
            post :verify_reproducibility
          end
        end

        # Signing Keys
        resources :signing_keys do
          member do
            post :rotate
            post :revoke
            get :public_key
          end
          collection do
            post :generate
          end
        end

        # Container Images
        resources :container_images do
          member do
            post :scan
            post :evaluate_policies
            get :vulnerabilities
            get :sbom
            post :quarantine
            post :verify
          end
          collection do
            get :statistics
          end
        end

        # Image Policies
        resources :image_policies do
          member do
            post :evaluate
            post :activate
            post :deactivate
          end
        end

        # Vulnerability Scans
        resources :vulnerability_scans, only: [:index, :show] do
          member do
            get :details
          end
        end

        # CVE Monitors
        resources :cve_monitors do
          collection do
            post :run_all
          end
          member do
            post :run
            post :pause
            post :resume
            get :alerts
          end
        end

        # License Management
        resources :licenses, only: [:index, :show] do
          collection do
            get :categories
            post :check_compatibility
          end
        end

        resources :license_policies do
          member do
            post :evaluate
          end
        end

        resources :license_detections, only: [:index, :show] do
          member do
            post :mark_review
          end
        end

        resources :license_violations do
          collection do
            get :statistics
          end
          member do
            post :resolve
            post :request_exception
            post :approve_exception
            post :reject_exception
            post :acknowledge
          end
        end

        resources :attributions do
          collection do
            post :generate_notice_file
            get :export
          end
        end

        # Vendor Risk Management
        resources :vendors do
          member do
            post :assess
            post :reassess
            get :risk_profile
            get :monitoring_events
          end
          collection do
            get :statistics
            get :risk_dashboard
          end
          resources :assessments, controller: "risk_assessments", only: [:index, :show, :create] do
            member do
              post :submit_for_review
              post :complete
            end
          end
          resources :questionnaires, controller: "questionnaire_responses", only: [:index, :show, :create] do
            member do
              post :send_reminder
              post :submit
              post :review
            end
          end
        end

        # Questionnaire Templates
        resources :questionnaire_templates do
          member do
            post :duplicate
            post :publish
            post :unpublish
            post :send_to_vendor
          end
        end

        # Questionnaire Responses
        resources :questionnaire_responses, only: [:index, :show, :update] do
          member do
            post :submit
            post :review
            post :send_reminder
            post :approve
            post :reject
            post :request_changes
          end
          collection do
            get "token/:token", to: "questionnaire_responses#show_by_token"
            post "token/:token/submit", to: "questionnaire_responses#submit_by_token"
          end
        end

        # Vendor Monitoring Events
        resources :vendor_monitoring_events, only: [:index, :show] do
          member do
            post :acknowledge
            post :resolve
          end
        end

        # Scan Templates
        resources :scan_templates do
          member do
            post :install
            post :publish
            post :unpublish
          end
          collection do
            get :featured
            get :categories
          end
        end

        # Scan Instances
        resources :scan_instances do
          member do
            post :execute
            post :pause
            post :resume
            get :executions
          end
        end

        # Scan Executions
        resources :scan_executions, only: [:index, :show] do
          member do
            post :cancel
            get :logs
          end
        end

        # Reports
        resources :reports do
          member do
            get :download
            post :regenerate
          end
          collection do
            post :generate_sbom
            post :generate_attribution
            post :generate_compliance
            post :generate_vulnerability
            post :generate_vendor_risk
          end
        end

        # Dashboard and analytics
        get :dashboard, to: "dashboard#index"
        get :analytics, to: "dashboard#analytics"
        get :compliance_summary, to: "dashboard#compliance_summary"
      end
    end
  end
end
