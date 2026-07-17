/** @type {import('next').NextConfig} */
const CLOUD_RUN_DEFAULT =
  "https://tumahelper-prod-api-550454647742.europe-west1.run.app";

const nextConfig = {
  async rewrites() {
    // Frontend currently calls local Next.js `/api/*` routes.
    // `/api/v1/*` is reserved for the Cloud Run backend.
    // Live Cloud Run only exposes `/health` today — `/api/*` returns 404.
    // Default: alias /api/v1 → local /api until USE_CLOUD_RUN_API=true.
    const useCloudRun = process.env.USE_CLOUD_RUN_API === "true";
    const cloudRunBase = (
      process.env.CLOUD_RUN_API_BASE_URL || CLOUD_RUN_DEFAULT
    ).replace(/\/$/, "");

    if (!useCloudRun) {
      return [
        {
          source: "/api/v1/:path*",
          destination: "/api/:path*",
        },
      ];
    }

    return [
      {
        source: "/api/v1/health",
        destination: `${cloudRunBase}/health`,
      },
      {
        source: "/api/v1/:path*",
        destination: `${cloudRunBase}/api/:path*`,
      },
    ];
  },
  images: {
    domains: ["localhost", "*.supabase.co", "images.unsplash.com"],
  },
  experimental: {
    serverActions: {
      bodySizeLimit: "5mb",
    },
  },
};

module.exports = nextConfig;
