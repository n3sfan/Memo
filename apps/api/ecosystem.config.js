module.exports = {
  apps: [
    {
      name: 'memory-map-api',
      cwd: __dirname,
      script: 'dist/main.js',
      exec_mode: 'cluster',
      instances: process.env.WEB_CONCURRENCY || 'max',
      instance_var: 'INSTANCE_ID',
      watch: false,
      autorestart: true,
      max_memory_restart: process.env.PM2_MAX_MEMORY || '512M',
      kill_timeout: 10000,
      listen_timeout: 10000,
      merge_logs: true,
      time: true,
      env: {
        NODE_ENV: 'production',
        PORT: process.env.PORT || 3000,
      },
    },
  ],
};
