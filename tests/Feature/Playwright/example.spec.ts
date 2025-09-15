import { test, expect } from '@playwright/test';

test('homepage has title and loads assets', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/Exertion|Laravel|Dashboard/i);
    await expect(page.locator('body')).toBeVisible();
});


