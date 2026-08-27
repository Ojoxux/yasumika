export interface DayEntry {
  date: string;
  label: string;
}

export interface CalendarConfig {
  closedDates: DayEntry[];
  openDates: DayEntry[];
}

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

export function validateCalendarConfig(input: unknown): CalendarConfig {
  if (typeof input !== "object" || input === null) {
    throw new Error("calendar config must be an object");
  }
  const obj = input as Record<string, unknown>;
  return {
    closedDates: validateDayEntries(obj.closedDates, "closedDates"),
    openDates: validateDayEntries(obj.openDates, "openDates"),
  };
}

function validateDayEntries(value: unknown, fieldName: string): DayEntry[] {
  if (!Array.isArray(value)) {
    throw new Error(`${fieldName} must be an array`);
  }
  return value.map((entry, index) => validateDayEntry(entry, fieldName, index));
}

function validateDayEntry(entry: unknown, fieldName: string, index: number): DayEntry {
  if (typeof entry !== "object" || entry === null) {
    throw new Error(`${fieldName}[${index}] must be an object`);
  }
  const { date, label } = entry as Record<string, unknown>;
  if (typeof date !== "string" || !DATE_PATTERN.test(date)) {
    throw new Error(`${fieldName}[${index}].date must be a YYYY-MM-DD string`);
  }
  if (typeof label !== "string" || label.length === 0) {
    throw new Error(`${fieldName}[${index}].label must be a non-empty string`);
  }
  return { date, label };
}
