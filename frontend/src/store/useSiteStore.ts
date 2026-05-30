import { create } from 'zustand';

export interface ParkingSite {
  id: string;
  name: string;
  capacity: number;
  status: "active" | "maintenance" | "offline";
  location: string;
  occupancy?: { name: string; count: number }[];
}

export const defaultParkingSites: ParkingSite[] = [
  { id: "all", name: "All Sites (Global)", capacity: 0, status: "active", location: "Global Overview", occupancy: [] },
];

interface SiteStore {
  activeSiteId: string;
  setActiveSiteId: (id: string) => void;
  parkingSites: ParkingSite[];
  setParkingSites: (sites: ParkingSite[]) => void;
  addSite: (site: ParkingSite) => void;
  removeSite: (id: string) => void;
  updateSite: (id: string, site: Partial<ParkingSite>) => void;
}

export const useSiteStore = create<SiteStore>((set) => ({
  activeSiteId: "all",
  setActiveSiteId: (id) => set({ activeSiteId: id }),
  parkingSites: defaultParkingSites,
  setParkingSites: (sites) => set({ parkingSites: sites }),
  addSite: (site) => set((state) => ({ parkingSites: [...state.parkingSites, site] })),
  removeSite: (id) => set((state) => ({ parkingSites: state.parkingSites.filter(s => s.id !== id) })),
  updateSite: (id, updatedSite) => set((state) => ({
    parkingSites: state.parkingSites.map(s => s.id === id ? { ...s, ...updatedSite } : s)
  })),
}));
