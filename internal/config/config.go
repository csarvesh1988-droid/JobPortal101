package config

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all configuration for our application
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Storage  StorageConfig
	SMTP     SMTPConfig
	App      AppConfig
	Security SecurityConfig
}

type ServerConfig struct {
	Port        string
	Environment string
	GinMode     string
}

type DatabaseConfig struct {
	URL             string
	MaxConnections  int
	MaxIdleTime     time.Duration
	MaxLifetime     time.Duration
}

type RedisConfig struct {
	URL      string
	Password string
	DB       int
}

type JWTConfig struct {
	Secret string
	Expiry time.Duration
}

type StorageConfig struct {
	Endpoint        string
	AccessKey       string
	SecretKey       string
	Bucket          string
	UseSSL          bool
	MaxResumeSizeMB int
	MaxImageSizeMB  int
	AllowedImageTypes    []string
	AllowedDocumentTypes []string
}

type SMTPConfig struct {
	Enabled   bool
	Host      string
	Port      int
	Username  string
	Password  string
	FromEmail string
	FromName  string
}

type AppConfig struct {
	SignupBonusPoints           int
	ProfileCompletionBonus      int
	ReferralBonusPoints         int
	MaxApplicationsPerDay       int
	FeaturedJobDurationDays     int
	RateLimitRequestsPerMinute  int
	RateLimitBurst             int
}

type SecurityConfig struct {
	BcryptCost         int
	CorsAllowedOrigins []string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() (*Config, error) {
	// Load .env file if it exists (development)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	config := &Config{
		Server: ServerConfig{
			Port:        getEnv("PORT", "8080"),
			Environment: getEnv("ENVIRONMENT", "development"),
			GinMode:     getEnv("GIN_MODE", "debug"),
		},
		Database: DatabaseConfig{
			URL:             getEnv("DATABASE_URL", "postgres://postgres:password@localhost:5432/jobportal101?sslmode=disable"),
			MaxConnections:  getEnvAsInt("DB_MAX_CONNECTIONS", 25),
			MaxIdleTime:     getEnvAsDuration("DB_MAX_IDLE_TIME", "30m"),
			MaxLifetime:     getEnvAsDuration("DB_MAX_LIFETIME", "1h"),
		},
		Redis: RedisConfig{
			URL:      getEnv("REDIS_URL", "redis://localhost:6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		JWT: JWTConfig{
			Secret: getEnv("JWT_SECRET", "your-secret-key"),
			Expiry: getEnvAsDuration("JWT_EXPIRY", "24h"),
		},
		Storage: StorageConfig{
			Endpoint:             getEnv("STORAGE_ENDPOINT", "localhost:9000"),
			AccessKey:            getEnv("STORAGE_ACCESS_KEY", "minioadmin"),
			SecretKey:            getEnv("STORAGE_SECRET_KEY", "minioadmin"),
			Bucket:               getEnv("STORAGE_BUCKET", "jobportal-files"),
			UseSSL:               getEnvAsBool("STORAGE_USE_SSL", false),
			MaxResumeSizeMB:      getEnvAsInt("MAX_RESUME_SIZE_MB", 5),
			MaxImageSizeMB:       getEnvAsInt("MAX_IMAGE_SIZE_MB", 2),
			AllowedImageTypes:    getEnvAsSlice("ALLOWED_IMAGE_TYPES", "jpg,jpeg,png,webp"),
			AllowedDocumentTypes: getEnvAsSlice("ALLOWED_DOCUMENT_TYPES", "pdf,doc,docx"),
		},
		SMTP: SMTPConfig{
			Enabled:   getEnvAsBool("SMTP_ENABLED", false),
			Host:      getEnv("SMTP_HOST", ""),
			Port:      getEnvAsInt("SMTP_PORT", 587),
			Username:  getEnv("SMTP_USERNAME", ""),
			Password:  getEnv("SMTP_PASSWORD", ""),
			FromEmail: getEnv("SMTP_FROM_EMAIL", "noreply@jobportal101.com"),
			FromName:  getEnv("SMTP_FROM_NAME", "JobPortal101"),
		},
		App: AppConfig{
			SignupBonusPoints:          getEnvAsInt("SIGNUP_BONUS_POINTS", 50),
			ProfileCompletionBonus:     getEnvAsInt("PROFILE_COMPLETION_BONUS", 100),
			ReferralBonusPoints:        getEnvAsInt("REFERRAL_BONUS_POINTS", 200),
			MaxApplicationsPerDay:      getEnvAsInt("MAX_APPLICATIONS_PER_DAY", 10),
			FeaturedJobDurationDays:    getEnvAsInt("FEATURED_JOB_DURATION_DAYS", 30),
			RateLimitRequestsPerMinute: getEnvAsInt("RATE_LIMIT_REQUESTS_PER_MINUTE", 60),
			RateLimitBurst:             getEnvAsInt("RATE_LIMIT_BURST", 10),
		},
		Security: SecurityConfig{
			BcryptCost:         getEnvAsInt("BCRYPT_COST", 12),
			CorsAllowedOrigins: getEnvAsSlice("CORS_ALLOWED_ORIGINS", "http://localhost:3000"),
		},
	}

	// Validate required fields
	if err := config.validate(); err != nil {
		return nil, err
	}

	return config, nil
}

// validate checks that all required configuration is present
func (c *Config) validate() error {
	if c.Database.URL == "" {
		return fmt.Errorf("DATABASE_URL is required")
	}
	if c.JWT.Secret == "" || c.JWT.Secret == "your-secret-key" {
		return fmt.Errorf("JWT_SECRET must be set to a secure value")
	}
	return nil
}

// Helper functions for environment variable parsing
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getEnvAsInt(key string, fallback int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return fallback
}

func getEnvAsBool(key string, fallback bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return fallback
}

func getEnvAsDuration(key string, fallback string) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	if duration, err := time.ParseDuration(fallback); err == nil {
		return duration
	}
	return time.Hour // Safe fallback
}

func getEnvAsSlice(key string, fallback string) []string {
	value := getEnv(key, fallback)
	return strings.Split(value, ",")
}