import { test, expect } from '@playwright/test';

// Boots the exported web build and fails on any page error.
// Extend with a scripted path through the game once there is one.

const url = process.env.BEAM_WEB_URL ?? 'http://localhost:8000/';

test('web build boots', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', (e) => errors.push(e.message));

  await page.goto(url);
  await expect(page.locator('canvas')).toBeVisible();
  await page.waitForTimeout(5000);
  await page.screenshot({ path: 'test-results/boot.png' });

  expect(errors).toEqual([]);
});
