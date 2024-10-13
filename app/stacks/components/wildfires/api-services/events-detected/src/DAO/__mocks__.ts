import { Event } from "../@types";

export const events: Event[] = [
    {
        id: 1,
        municipality_id: 1,
        detected_from: 'SAT',
        detection_time: "2024-01-01 10:00:00",
        geometry: {
            type: "MultyPoligon",
            coordinates: [
                [[1, 2], [3, 4]]
            ]
        }
    },
    {
        id: 2,
        municipality_id: 1,
        detected_from: 'SAT',
        detection_time: "2024-01-02 10:00:00",
        geometry: {
            type: "MultyPoligon",
            coordinates: [
                [[1, 2], [3, 4]]
            ]
        }
    },
    {
        id: 3,
        municipality_id: 2,
        detected_from: 'SAT',
        detection_time: "2024-02-02 10:00:00",
        geometry: {
            type: "MultyPoligon",
            coordinates: [
                [[1, 2], [3, 4]]
            ]
        }
    },
    {
        id: 4,
        municipality_id: 3,
        detected_from: 'SIG',
        detection_time: "2024-01-02 10:00:00",
        geometry: {
            type: "Point",
            coordinates: [1, 2]
        }
    },
];