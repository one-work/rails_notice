Rails.application.routes.draw do
  concern :notice do
    resources :notifications, only: [:index, :show, :destroy] do
      collection do
        get :readed
        post :read_all
      end
      member do
        get :url
        patch :read
        match :archive, via: [:put, :patch]
      end
    end
    resource :notification_setting, only: [:show, :edit, :update]
  end

  namespace :notice, defaults: { business: 'notice' } do
    namespace :admin, defaults: { namespace: 'admin' } do
      root 'home#index'
      resources :user_notifications do
        member do
          patch :push
          patch :email
        end
      end
      resources :member_notifications do
        member do
          patch :push
          patch :email
        end
      end
      resources :notify_settings do
        collection do
          get :columns
        end
      end
      resources :users
      resources :members
      resources :announcements do
        member do
          match :edit_user, via: [:get, :post]
          patch 'user' => :update_user
          get 'publish/options' => :options
          match :publish, via: [:get, :post]
        end
        resources :announcement_user_tags
        resources :announcement_organs
      end
    end

    namespace :me, defaults: { namespace: 'me' } do
      concerns :notice
    end

    namespace :my, defaults: { namespace: 'my' } do
      concerns :notice
    end

    namespace :board, defaults: { namespace: 'board' } do
      concerns :notice
    end
  end
end
