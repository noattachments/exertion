import { test, expect } from '@playwright/experimental-ct-react';
import { Button } from '@/components/ui/button';

test.use({ viewport: { width: 640, height: 480 } });

test('renders Button and handles click', async ({ mount }) => {
    let clicked = false;
    const component = await mount(<Button onClick={() => (clicked = true)}>Click me</Button>);
    await expect(component).toContainText('Click me');
    await component.click();
    expect(clicked).toBeTruthy();
});


