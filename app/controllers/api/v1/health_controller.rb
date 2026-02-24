# frozen_string_literal: true

module Api
  module V1
    # Returns health, readiness, and metrics information.
    # These endpoints are intentionally public (no auth required).
    class HealthController < ApplicationController
      # GET /health
      # Basic liveness probe — returns 200 if the process is running.
      def show
        render json: {
          status: "ok",
          service: "user_service",
          version: ENV.fetch("APP_VERSION", "unknown"),
          timestamp: Time.current.iso8601
        }
      end

      # GET /readiness
      # Kubernetes-style readiness probe — verifies DB and Redis connectivity.
      def readiness
        checks = {
          database: check_database,
          redis: check_redis
        }

        all_ok = checks.values.all? { |c| c[:status] == "ok" }

        render json: {
          status: all_ok ? "ok" : "degraded",
          checks: checks,
          timestamp: Time.current.iso8601
        }, status: all_ok ? :ok : :service_unavailable
      end

      # GET /metrics
      # Lightweight metrics for monitoring dashboards.
      def metrics
        render json: {
          users: {
            total: User.count,
            active: User.status_active.count,
            pending: User.status_pending.count,
            banned: User.status_banned.count
          },
          timestamp: Time.current.iso8601
        }
      end

      private

      def check_database
        ActiveRecord::Base.connection.execute("SELECT 1")
        { status: "ok" }
      rescue StandardError => e
        { status: "error", message: e.message }
      end

      def check_redis
        RedisClient.with { |conn| conn.ping }
        { status: "ok" }
      rescue StandardError => e
        { status: "error", message: e.message }
      end
    end
  end
end
