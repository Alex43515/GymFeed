import { BetaAnalyticsDataClient } from "@google-analytics/data";

const METRICS = [
  "activeUsers",
  "newUsers",
  "sessions",
  "engagedSessions",
  "eventCount",
  "keyEvents",
];

function metricObject(response) {
  const values = response.rows?.[0]?.metricValues ?? [];
  return Object.fromEntries(METRICS.map((name, index) => [
    name,
    Number(values[index]?.value ?? 0),
  ]));
}

function tabularRows(response) {
  const dimensions = response.dimensionHeaders?.map((item) => item.name) ?? [];
  const metrics = response.metricHeaders?.map((item) => item.name) ?? [];
  return (response.rows ?? []).map((row) => ({
    ...Object.fromEntries(dimensions.map((name, index) => [
      name,
      row.dimensionValues?.[index]?.value ?? "",
    ])),
    ...Object.fromEntries(metrics.map((name, index) => [
      name,
      Number(row.metricValues?.[index]?.value ?? 0),
    ])),
  }));
}

export class Ga4Reporter {
  constructor({ propertyId, credentialsPath, client } = {}) {
    this.propertyId = propertyId;
    this.client = client ?? (propertyId ? new BetaAnalyticsDataClient({
      keyFilename: credentialsPath,
    }) : null);
  }

  async runReport(request) {
    const [response] = await this.client.runReport({
      property: `properties/${this.propertyId}`,
      ...request,
    });
    return response;
  }

  async aggregate(startDate) {
    const response = await this.runReport({
      dateRanges: [{ startDate, endDate: "yesterday" }],
      metrics: METRICS.map((name) => ({ name })),
    });
    return metricObject(response);
  }

  async summary() {
    if (!this.propertyId || !this.client) {
      return { status: "not_configured" };
    }

    try {
      const [last7Days, last30Days, acquisition, screens] = await Promise.all([
        this.aggregate("7daysAgo"),
        this.aggregate("30daysAgo"),
        this.runReport({
          dateRanges: [{ startDate: "30daysAgo", endDate: "yesterday" }],
          dimensions: ["sessionSource", "sessionMedium", "sessionCampaignName", "sessionManualAdContent"]
            .map((name) => ({ name })),
          metrics: ["sessions", "activeUsers", "engagedSessions", "keyEvents"]
            .map((name) => ({ name })),
          orderBys: [{ metric: { metricName: "sessions" }, desc: true }],
          limit: 50,
        }),
        this.runReport({
          dateRanges: [{ startDate: "30daysAgo", endDate: "yesterday" }],
          dimensions: ["platform", "unifiedScreenName"].map((name) => ({ name })),
          metrics: ["screenPageViews", "activeUsers"].map((name) => ({ name })),
          orderBys: [{ metric: { metricName: "screenPageViews" }, desc: true }],
          limit: 50,
        }),
      ]);

      return {
        status: "ok",
        property_id: this.propertyId,
        through: "yesterday",
        last_7_days: last7Days,
        last_30_days: last30Days,
        acquisition_30d: tabularRows(acquisition),
        screens_30d: tabularRows(screens),
      };
    } catch (error) {
      return {
        status: "error",
        message: error instanceof Error ? error.message : String(error),
      };
    }
  }
}
