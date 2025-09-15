import { defineConfig, devices } from '@playwright/experimental-ct-react';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const resourcesJs = resolve(__dirname, 'resources/js');

// Component testing config for React + Vite
export default defineConfig({
    testDir: './tests/Component/Playwright',
    reporter: 'list',
    fullyParallel: true,
    retries: process.env.CI ? 2 : 0,
    use: {
        ctTemplateDir: 'playwright',
        ctViteConfig: {
            plugins: [react(), tailwindcss()],
            resolve: {
                alias: {
                    '@': resourcesJs,
                },
            },
        },
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    ],
});


