"use client";

import { useMemo, useState } from "react";
import { ArrowUpRight, LayoutGrid, ListFilter, Search, SlidersHorizontal } from "lucide-react";
import { PlaceCard } from "@/components/ui";
import type { Place } from "@/types/roamora";

const filters = ["All places", "Cafés", "Outdoors", "Culture"];

export function ExploreContent({ places }: { places: Place[] }) {
  const [category, setCategory] = useState("All places");
  const [query, setQuery] = useState("");
  const [saved, setSaved] = useState<string[]>([]);
  const filteredPlaces = useMemo(() => places.filter((place) => {
    const matchesCategory = category === "All places" || place.category.toLowerCase().includes(category.toLowerCase());
    const searchText = `${place.name} ${place.neighborhood} ${place.description}`.toLowerCase();
    return matchesCategory && searchText.includes(query.toLowerCase());
  }), [category, places, query]);
  function toggleSaved(id: string) {
    setSaved((current) => current.includes(id) ? current.filter((value) => value !== id) : [...current, id]);
  }

  return (
    <>
      <div className="explore-toolbar">
        <div className="filter-tabs" role="tablist" aria-label="Place categories">{filters.map((filter) => <button aria-selected={category === filter} className={category === filter ? "filter-tab selected" : "filter-tab"} key={filter} onClick={() => setCategory(filter)} role="tab" type="button">{filter}</button>)}</div>
        <label className="explore-search"><Search size={17} /><input aria-label="Search places" onChange={(event) => setQuery(event.target.value)} placeholder="Find a place or mood…" value={query} /><SlidersHorizontal size={16} /></label>
      </div>
      <div className="explore-view-line"><span><strong>{filteredPlaces.length}</strong> curated spots <i>·</i> New Delhi sample</span><span className="view-switch"><button aria-label="Grid view" className="view-selected" type="button"><LayoutGrid size={16} /></button><button aria-label="List view (preview only)" type="button"><ListFilter size={16} /></button></span></div>
      {filteredPlaces.length > 0 ? <div className="place-grid explore-grid">{filteredPlaces.map((place) => (
        <article className="explore-place-wrap" key={place.id}><PlaceCard place={place} /><button aria-pressed={saved.includes(place.id)} className={saved.includes(place.id) ? "save-place is-saved" : "save-place"} onClick={() => toggleSaved(place.id)} type="button">{saved.includes(place.id) ? "Saved" : "Save place"}</button></article>
      ))}</div> : <div className="state-card state-empty"><span className="empty-sparkle"><Search size={20} /></span><h2>No places found</h2><p>Try a different search or category.</p><button className="button button-outline" onClick={() => { setQuery(""); setCategory("All places"); }} type="button">Clear filters <ArrowUpRight size={15} /></button></div>}
      <div className="explore-disclaimer"><span>✳</span>Curated demo ideas — distances and details are illustrative, not live.</div>
    </>
  );
}
