import { describe, expect, it } from "vitest";
import { validateCalendarConfig } from "../src/calendar";

describe("validateCalendarConfig", () => {
  it("accepts a valid config", () => {
    const input = {
      closedDates: [{ date: "2026-08-27", label: "休み" }],
      openDates: [],
    };
    expect(validateCalendarConfig(input)).toEqual(input);
  });

  it("rejects a non-object input", () => {
    expect(() => validateCalendarConfig("not an object")).toThrow();
  });

  it("rejects a closedDates entry with an invalid date format", () => {
    const input = {
      closedDates: [{ date: "2026/08/27", label: "休み" }],
      openDates: [],
    };
    expect(() => validateCalendarConfig(input)).toThrow(/date/);
  });

  it("rejects a closedDates entry with an empty label", () => {
    const input = {
      closedDates: [{ date: "2026-08-27", label: "" }],
      openDates: [],
    };
    expect(() => validateCalendarConfig(input)).toThrow(/label/);
  });

  it("rejects a config missing the openDates field", () => {
    const input = { closedDates: [] };
    expect(() => validateCalendarConfig(input)).toThrow(/openDates/);
  });
});
