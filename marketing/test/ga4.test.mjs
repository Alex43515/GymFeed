import test from "node:test";
import assert from "node:assert/strict";
import { Ga4Reporter } from "../src/providers/ga4.mjs";

test("GA4 reporter is optional until a property is configured", async () => {
  assert.deepEqual(await new Ga4Reporter().summary(), { status: "not_configured" });
});

test("GA4 reporter gives the CMO aggregate, acquisition and screen context", async () => {
  const requests = [];
  const client = {
    runReport: async (request) => {
      requests.push(request);
      if (!request.dimensions) {
        return [{
          rows: [{ metricValues: ["10", "6", "12", "8", "40", "2"].map((value) => ({ value })) }],
        }];
      }
      return [{
        dimensionHeaders: request.dimensions,
        metricHeaders: request.metrics,
        rows: [{
          dimensionValues: request.dimensions.map(({ name }) => ({ value: `${name}-value` })),
          metricValues: request.metrics.map((_metric, index) => ({ value: String(index + 1) })),
        }],
      }];
    },
  };
  const summary = await new Ga4Reporter({ propertyId: "123456789", client }).summary();

  assert.equal(summary.status, "ok");
  assert.equal(summary.last_7_days.activeUsers, 10);
  assert.equal(summary.last_30_days.keyEvents, 2);
  assert.equal(summary.acquisition_30d[0].sessions, 1);
  assert.equal(summary.screens_30d[0].screenPageViews, 1);
  assert.ok(requests.every((request) => request.property === "properties/123456789"));
});
