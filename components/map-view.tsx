"use client";

import { useEffect, useRef, useState } from "react";
import {
  Compass,
  Gift,
  Locate,
  MapPin,
  Navigation,
  Radio,
  Sparkles,
  Zap,
} from "lucide-react";
import confetti from "canvas-confetti";
import { apiRequest } from "@/lib/api/browser-client";
import type { CollectibleItem, Drop } from "@/types/roamora";

interface MapViewProps {
  items: Drop[];
  collectibles?: CollectibleItem[];
}

export function MapView({ items, collectibles = [] }: MapViewProps) {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const leafletMapRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const userMarkerRef = useRef<any>(null);
  const userCircleRef = useRef<any>(null);

  const [selectedItem, setSelectedItem] = useState<{
    type: "drop" | "collectible";
    data: any;
  } | null>(null);

  const [userLocation, setUserLocation] = useState<{
    lat: number;
    lng: number;
    accuracy: number;
  } | null>(null);

  const [locationStatus, setLocationStatus] = useState<
    "idle" | "requesting" | "granted" | "denied"
  >("idle");

  const [remoteMode, setRemoteMode] = useState(false);
  const [collecting, setCollecting] = useState(false);
  const [collectNotice, setCollectNotice] = useState("");
  const [collectError, setCollectError] = useState("");
  const [collectedSlugs, setCollectedSlugs] = useState<Set<string>>(new Set());

  // Default coordinate center: New Delhi Hauz Khas / Lodhi Garden
  const defaultCoords = { lat: 28.5535, lng: 77.1942 };

  // Request browser geolocation with user consent
  function requestLocation() {
    if (!navigator.geolocation) {
      setLocationStatus("denied");
      return;
    }
    setLocationStatus("requesting");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const coords = {
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
          accuracy: pos.coords.accuracy,
        };
        setUserLocation(coords);
        setLocationStatus("granted");
        if (leafletMapRef.current) {
          leafletMapRef.current.setView([coords.lat, coords.lng], 16);
        }
      },
      () => {
        setLocationStatus("denied");
        // Fallback to default coordinates
        setUserLocation({ ...defaultCoords, accuracy: 20 });
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 30000 },
    );
  }

  // Initialize Leaflet Map
  useEffect(() => {
    let mapInstance: any = null;

    async function initMap() {
      if (typeof window === "undefined" || !mapContainerRef.current) return;
      try {
        const L = (await import("leaflet")).default;

        if (leafletMapRef.current) {
          leafletMapRef.current.remove();
        }

        const initialLat = userLocation?.lat ?? defaultCoords.lat;
        const initialLng = userLocation?.lng ?? defaultCoords.lng;

        mapInstance = L.map(mapContainerRef.current, {
          center: [initialLat, initialLng],
          zoom: 15,
          zoomControl: true,
        });

        // Add OpenStreetMap tile layer
        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
          maxZoom: 19,
        }).addTo(mapInstance);

        leafletMapRef.current = mapInstance;

        // Render markers
        renderMarkers(L, mapInstance);
      } catch (err) {
        console.error("Map initialization error:", err);
      }
    }

    void initMap();

    return () => {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, []);

  // Update map markers when items, collectibles or userLocation change
  useEffect(() => {
    async function updateMarkers() {
      if (!leafletMapRef.current) return;
      const L = (await import("leaflet")).default;
      renderMarkers(L, leafletMapRef.current);
    }
    void updateMarkers();
  }, [items, collectibles, userLocation, remoteMode, collectedSlugs]);

  function renderMarkers(L: any, map: any) {
    // Clear previous markers
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];

    if (userMarkerRef.current) userMarkerRef.current.remove();
    if (userCircleRef.current) userCircleRef.current.remove();

    // 1. User Position Marker & Radar Pulse Circle
    if (userLocation) {
      const userIcon = L.divIcon({
        className: "user-radar-pin",
        html: `<div class="relative flex items-center justify-center">
                 <div class="w-5 h-5 rounded-full bg-coral border-2 border-white shadow-lg animate-pulse"></div>
                 <div class="absolute w-12 h-12 rounded-full border border-coral/40 bg-coral/10 animate-ping"></div>
               </div>`,
        iconSize: [24, 24],
        iconAnchor: [12, 12],
      });

      userMarkerRef.current = L.marker([userLocation.lat, userLocation.lng], {
        icon: userIcon,
        zIndexOffset: 1000,
      }).addTo(map);

      // Radar range circle (500m or 150m)
      userCircleRef.current = L.circle([userLocation.lat, userLocation.lng], {
        radius: remoteMode ? 1000 : 250,
        color: "#f06b72",
        fillColor: "#f06b72",
        fillOpacity: 0.08,
        weight: 1.5,
        dashArray: "4, 6",
      }).addTo(map);
    }

    // 2. Virtual Collectibles Markers
    collectibles.forEach((item) => {
      const lat = item.latitude ?? defaultCoords.lat;
      const lng = item.longitude ?? defaultCoords.lng;
      const isCollected = collectedSlugs.has(item.slug);

      const rarityColor =
        item.rarity === "LEGENDARY"
          ? "#F59E0B"
          : item.rarity === "EPIC"
          ? "#8B5CF6"
          : item.rarity === "RARE"
          ? "#3B82F6"
          : "#10B981";

      const icon = L.divIcon({
        className: "collectible-map-pin",
        html: `<div class="cursor-pointer transform hover:scale-125 transition-transform flex flex-col items-center">
                 <div class="w-10 h-10 rounded-2xl flex items-center justify-center text-xl shadow-lg border-2 bg-white"
                      style="border-color: ${rarityColor}; opacity: ${isCollected ? 0.45 : 1}">
                   ${item.icon}
                 </div>
                 <span class="text-[10px] font-bold bg-ink text-white px-1.5 py-0.5 rounded shadow mt-1 whitespace-nowrap">
                   ${item.name}
                 </span>
               </div>`,
        iconSize: [44, 52],
        iconAnchor: [22, 26],
      });

      const marker = L.marker([lat, lng], { icon }).addTo(map);
      marker.on("click", () => {
        setSelectedItem({ type: "collectible", data: item });
        setCollectError("");
        setCollectNotice("");
      });
      markersRef.current.push(marker);
    });

    // 3. Community Drops Markers
    items.forEach((drop) => {
      const lat = drop.latitude ?? defaultCoords.lat + (drop.y - 50) * 0.001;
      const lng = drop.longitude ?? defaultCoords.lng + (drop.x - 50) * 0.001;

      const dropIcon = L.divIcon({
        className: "drop-map-pin",
        html: `<div class="cursor-pointer transform hover:scale-125 transition-transform flex flex-col items-center">
                 <div class="w-9 h-9 rounded-full bg-coral text-white flex items-center justify-center shadow-md border-2 border-white">
                   <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"></path><circle cx="12" cy="10" r="3"></circle></svg>
                 </div>
                 <span class="text-[9px] font-semibold bg-white text-ink px-1.5 py-0.5 rounded shadow mt-0.5 whitespace-nowrap border border-pink-100">
                   ${drop.title}
                 </span>
               </div>`,
        iconSize: [36, 44],
        iconAnchor: [18, 22],
      });

      const marker = L.marker([lat, lng], { icon: dropIcon }).addTo(map);
      marker.on("click", () => {
        setSelectedItem({ type: "drop", data: drop });
        setCollectError("");
        setCollectNotice("");
      });
      markersRef.current.push(marker);
    });
  }

  // Handle server-side distance validated collection
  async function handleCollect(item: CollectibleItem) {
    if (collecting) return;
    setCollecting(true);
    setCollectError("");
    setCollectNotice("");

    const coords = userLocation ?? defaultCoords;

    try {
      const res = await apiRequest<{ success: boolean; message: string; quantity: number }>(
        `/collectibles/${item.id}/collect`,
        {
          method: "POST",
          body: JSON.stringify({
            latitude: coords.lat,
            longitude: coords.lng,
            accuracyMeters: userLocation?.accuracy ?? 10,
            locationConsent: true,
            remoteMode,
          }),
        },
      );

      setCollectedSlugs((prev) => new Set([...prev, item.slug]));
      setCollectNotice(res.message);

      // Confetti celebration
      try {
        confetti({
          particleCount: 80,
          spread: 60,
          origin: { y: 0.7 },
        });
      } catch {
        // Ignore
      }
    } catch (err: any) {
      setCollectError(err.message || "Failed to collect item. Are you close enough?");
    } finally {
      setCollecting(false);
    }
  }

  // Calculate distance between user and selected item
  function getDistanceLabel(lat?: number | null, lng?: number | null): string {
    if (!lat || !lng || !userLocation) return "Location approximate";
    const R = 6371000;
    const dLat = ((lat - userLocation.lat) * Math.PI) / 180;
    const dLon = ((lng - userLocation.lng) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((userLocation.lat * Math.PI) / 180) *
        Math.cos((lat * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const d = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    if (d < 1000) return `${Math.round(d)} meters away`;
    return `${(d / 1000).toFixed(1)} km away`;
  }

  return (
    <div className="adventure-map-container flex flex-col lg:flex-row gap-6 my-6">
      {/* Map display */}
      <div className="relative flex-1 rounded-2xl overflow-hidden border border-line shadow-md min-h-[500px]">
        {/* Leaflet map container */}
        <div ref={mapContainerRef} className="w-full h-full min-h-[500px] z-10" />

        {/* Map controls overlay */}
        <div className="absolute top-4 right-4 z-20 flex flex-col gap-2">
          <button
            type="button"
            onClick={requestLocation}
            className="p-3 bg-white/95 hover:bg-white text-ink rounded-xl shadow-lg border border-pink-100 flex items-center gap-2 text-xs font-bold transition-transform hover:scale-105"
            title="Recenter on your location"
          >
            <Locate size={16} className={locationStatus === "granted" ? "text-green-600" : "text-coral"} />
            <span>{locationStatus === "granted" ? "My Location" : "Locate Me"}</span>
          </button>

          <button
            type="button"
            onClick={() => setRemoteMode((r) => !r)}
            className={`p-3 rounded-xl shadow-lg border text-xs font-bold flex items-center gap-2 transition-all ${
              remoteMode
                ? "bg-coral text-white border-coral"
                : "bg-white/95 text-ink border-pink-100 hover:bg-white"
            }`}
            title="Toggle Remote Exploration without walking"
          >
            <Radio size={16} />
            <span>{remoteMode ? "Remote: Active" : "Remote Mode"}</span>
          </button>
        </div>

        {/* Map radar bottom legend banner */}
        <div className="absolute bottom-4 left-4 right-4 z-20 bg-white/90 backdrop-blur-md p-3 rounded-xl shadow-lg border border-pink-100 flex flex-wrap items-center justify-between gap-3 text-xs">
          <div className="flex items-center gap-3">
            <span className="flex items-center gap-1.5 font-semibold text-ink">
              <span className="w-3 h-3 rounded-full bg-coral inline-block animate-ping" /> Radar Active
            </span>
            <span className="text-muted hidden sm:inline">· Tap markers to inspect & collect</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1 bg-pink-50 text-coral-dark px-2.5 py-1 rounded-lg font-bold text-[11px]">
              <Compass size={13} /> {collectibles.length} Collectibles
            </span>
            <span className="inline-flex items-center gap-1 bg-amber-50 text-amber-700 px-2.5 py-1 rounded-lg font-bold text-[11px]">
              <MapPin size={13} /> {items.length} Community Drops
            </span>
          </div>
        </div>
      </div>

      {/* Side details pane */}
      <aside className="w-full lg:w-80 shrink-0 flex flex-col gap-4">
        {selectedItem ? (
          selectedItem.type === "collectible" ? (
            <div className="p-5 bg-white rounded-2xl border border-pink-100 shadow-md">
              <div className="flex items-start justify-between">
                <span
                  className="px-2.5 py-0.5 rounded-full text-[10px] font-black tracking-wider uppercase text-white shadow-sm"
                  style={{
                    backgroundColor:
                      selectedItem.data.rarity === "LEGENDARY"
                        ? "#F59E0B"
                        : selectedItem.data.rarity === "EPIC"
                        ? "#8B5CF6"
                        : selectedItem.data.rarity === "RARE"
                        ? "#3B82F6"
                        : "#10B981",
                  }}
                >
                  {selectedItem.data.rarity}
                </span>
                <span className="text-xs text-muted font-medium">
                  {getDistanceLabel(selectedItem.data.latitude, selectedItem.data.longitude)}
                </span>
              </div>

              <div className="my-4 text-center">
                <div className="w-16 h-16 mx-auto rounded-3xl bg-pink-50 flex items-center justify-center text-3xl shadow-inner border border-pink-200">
                  {selectedItem.data.icon}
                </div>
                <h3 className="font-bold text-lg text-ink mt-2">{selectedItem.data.name}</h3>
                <p className="text-xs text-muted mt-1 leading-relaxed">
                  {selectedItem.data.description}
                </p>
              </div>

              {selectedItem.data.perkDescription && (
                <div className="p-3 bg-amber-50/70 border border-amber-200/60 rounded-xl mb-4 text-xs">
                  <span className="font-bold text-amber-900 block mb-0.5">Special Perk:</span>
                  <span className="text-amber-800">{selectedItem.data.perkDescription}</span>
                </div>
              )}

              {collectNotice && (
                <div className="p-3 bg-green-50 border border-green-200 rounded-xl text-green-700 text-xs font-semibold mb-3">
                  ✨ {collectNotice}
                </div>
              )}
              {collectError && (
                <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-red-700 text-xs font-medium mb-3">
                  ⚠️ {collectError}
                </div>
              )}

              <button
                type="button"
                disabled={collecting || collectedSlugs.has(selectedItem.data.slug)}
                onClick={() => void handleCollect(selectedItem.data)}
                className="button button-coral w-full py-3 font-bold text-xs shadow-md"
              >
                {collectedSlugs.has(selectedItem.data.slug) ? (
                  "Already in Inventory"
                ) : collecting ? (
                  "Collecting…"
                ) : (
                  <>
                    <Gift size={15} /> Collect Item
                  </>
                )}
              </button>
            </div>
          ) : (
            <div className="p-5 bg-white rounded-2xl border border-pink-100 shadow-md">
              <span className="text-[10px] font-bold text-coral-dark uppercase tracking-wider block mb-1">
                COMMUNITY DROP
              </span>
              <h3 className="font-bold text-lg text-ink">{selectedItem.data.title}</h3>
              <p className="text-xs text-muted mt-1 leading-relaxed">
                {selectedItem.data.description || "Shared meetup drop in Pookie Match."}
              </p>

              <div className="my-4 space-y-2 text-xs">
                <div className="flex items-center gap-2 text-ink">
                  <Navigation size={14} className="text-coral" />
                  <span>{selectedItem.data.area || "Neighborhood location"}</span>
                </div>
                <div className="flex items-center gap-2 text-muted">
                  <Sparkles size={14} className="text-coral" />
                  <span>Starts: {selectedItem.data.startsAt}</span>
                </div>
              </div>

              <div className="p-3 bg-pink-50 rounded-xl text-xs text-ink/80">
                <strong>Host interest:</strong> {selectedItem.data.interest}
              </div>
            </div>
          )
        ) : (
          <div className="p-5 bg-white rounded-2xl border border-pink-100 shadow-sm text-center">
            <div className="w-12 h-12 rounded-2xl bg-coral-pale text-coral flex items-center justify-center mx-auto mb-3">
              <Compass size={24} />
            </div>
            <h4 className="font-bold text-sm text-ink">Explore the Map</h4>
            <p className="text-xs text-muted mt-1 leading-relaxed">
              Tap on any virtual item or community drop pin to inspect its distance, description, and collect rewards.
            </p>
          </div>
        )}

        {/* Exploration info card */}
        <div className="p-4 bg-gradient-to-br from-pink-50/60 to-rose-50/60 border border-pink-200/50 rounded-2xl">
          <div className="flex items-center gap-2 mb-1.5">
            <Zap size={16} className="text-amber-500" />
            <h4 className="font-bold text-xs uppercase tracking-wider text-ink">
              Pokémon GO-Style Explorer
            </h4>
          </div>
          <p className="text-xs text-muted leading-relaxed">
            Walk within 50m of map coordinates to claim collectibles. You can also turn on{" "}
            <strong>Remote Mode</strong> in the top right to search without physical walking!
          </p>
        </div>
      </aside>
    </div>
  );
}
