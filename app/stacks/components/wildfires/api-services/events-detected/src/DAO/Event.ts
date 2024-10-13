import { Event, EventFilter } from "../@types";
import { events } from './__mocks__';

export class EventDAO {
    public async getEvents(filters: EventFilter): Promise<Array<Event>> {
        // TODO Replace this mock with implementation

        let eventsFound = events;

        if (filters.municipality !== undefined) {
            eventsFound = events.filter((e) => e.municipality_id === parseInt(filters.municipality as string));
        }

        return eventsFound;
    }

    public async getEventByID(id: string): Promise<Event | null> {
        // TODO Replace this mock with implementation

        const numericId = parseInt(id);

        const eventFound = events.filter((e) => e.id === numericId);

        if (eventFound.length === 0) return null;

        return eventFound[0];
    }
}
