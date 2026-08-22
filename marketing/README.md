# GymFeed marketing worker

This service implements the decision, generation, QA, budget, approval, publishing, and learning layers of GymFeed's marketing system. n8n only schedules authenticated worker endpoints; business logic remains version-controlled and testable here.

Safe defaults:

- `marketing_brand_config.enabled = false`
- `GENERATE_ASSETS=false`
- `AUTO_PUBLISH=false`
- imported n8n workflows are inactive

See [`../docs/MARKETING_AUTOMATION.md`](../docs/MARKETING_AUTOMATION.md) for deployment and activation.

Local checks:

```powershell
cd marketing
npm install
npm test
npm run check
```
