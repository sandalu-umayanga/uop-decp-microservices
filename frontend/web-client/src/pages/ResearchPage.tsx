import { useState, useEffect, useCallback } from "react";
import { useAuth } from "../context/AuthContext";
import { researchService } from "../services/research";
import type { 
  ResearchResponse, 
  ResearchCategory, 
  ProjectMemberDTO, 
  ProjectRole 
} from "../types";
import LoadingSpinner from "../components/common/LoadingSpinner";
import ErrorAlert from "../components/common/ErrorAlert";
import { formatDate } from "../utils/formatDate";

const CATEGORIES: ResearchCategory[] = [
  "PAPER",
  "THESIS",
  "PROJECT",
  "ARTICLE",
  "CONFERENCE",
  "WORKSHOP",
];

export default function ResearchPage() {
  const { user } = useAuth();
  const [papers, setPapers] = useState<ResearchResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [selectedPaper, setSelectedPaper] = useState<ResearchResponse | null>(
    null,
  );

  const fetchPapers = useCallback(async () => {
    try {
      setLoading(true);
      const params: Record<string, string> = {};
      if (search) params.search = search;
      if (category) params.category = category;
      const res = await researchService.getAll(params);
      setPapers(res.data);
    } catch {
      setError("Failed to load research papers");
    } finally {
      setLoading(false);
    }
  }, [search, category]);

  useEffect(() => {
    fetchPapers();
  }, [fetchPapers]);

  const canCreate = user?.role === "ALUMNI" || user?.role === "ADMIN";

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Research Hub</h1>
        {canCreate && (
          <button
            onClick={() => setShowCreate(true)}
            className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary-500/20 transition hover:brightness-110"
          >
            + Publish Research
          </button>
        )}
      </div>

      <div className="mb-6 flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <input
            type="text"
            placeholder="Search papers, authors, tags..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-xl border subtle-border bg-white/80 py-2 pl-4 pr-10 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
        </div>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
        >
          <option value="">All Categories</option>
          {CATEGORIES.map((c) => (
            <option key={c} value={c}>
              {c.replace(/_/g, " ")}
            </option>
          ))}
        </select>
      </div>

      {error && <ErrorAlert message={error} onClose={() => setError("")} />}

      {loading ? (
        <LoadingSpinner />
      ) : papers.length === 0 ? (
        <div className="glass-panel rounded-2xl p-12 text-center ink-muted">
          <p className="text-lg font-medium text-gray-900 dark:text-white">No research papers found</p>
          <p className="mt-1 text-sm">Try adjusting your filters or publish the first paper.</p>
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {papers.map((paper) => (
            <PaperCard
              key={paper.id}
              paper={paper}
              onSelect={setSelectedPaper}
            />
          ))}
        </div>
      )}

      {showCreate && (
        <CreatePaperModal
          onClose={() => setShowCreate(false)}
          onCreated={() => {
            setShowCreate(false);
            fetchPapers();
          }}
        />
      )}

      {selectedPaper && (
        <PaperDetailModal
          paper={selectedPaper}
          onClose={() => setSelectedPaper(null)}
          onUpdate={() => {
            fetchPapers();
            // Refresh selected paper if needed
            researchService.getById(selectedPaper.id).then(res => setSelectedPaper(res.data));
          }}
          onCite={async () => {
            try {
              await researchService.cite(selectedPaper.id);
              fetchPapers();
              const res = await researchService.getById(selectedPaper.id);
              setSelectedPaper(res.data);
            } catch {
              /* ignore */
            }
          }}
        />
      )}
    </div>
  );
}

function PaperCard({
  paper,
  onSelect,
}: {
  paper: ResearchResponse;
  onSelect: (p: ResearchResponse) => void;
}) {
  return (
    <div
      className="glass-panel group cursor-pointer rounded-2xl p-5 transition hover:-translate-y-0.5 hover:shadow-lg"
      onClick={() => onSelect(paper)}
    >
      <div className="mb-2 flex items-start justify-between gap-2">
        <span className="inline-block rounded-full bg-primary-500/15 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
          {paper.category?.replace(/_/g, " ") || "GENERAL"}
        </span>
        <div className="flex items-center gap-1.5 text-[10px] font-medium ink-muted">
          <span>{paper.views} views</span>
          <span>•</span>
          <span>{paper.citations} cites</span>
        </div>
      </div>
      <h3 className="mb-2 line-clamp-2 font-bold text-gray-900 transition group-hover:text-primary-600 dark:text-white dark:group-hover:text-primary-300">
        {paper.title}
      </h3>
      <p className="mb-4 line-clamp-2 text-sm leading-relaxed ink-muted">
        {paper.researchAbstract}
      </p>
      
      <div className="mb-4 flex flex-wrap gap-1.5">
        {paper.tags?.slice(0, 3).map((tag: string) => (
          <span
            key={tag}
            className="rounded bg-white/70 px-2 py-0.5 text-[10px] font-medium ink-muted dark:bg-white/10"
          >
            #{tag}
          </span>
        ))}
        {paper.tags?.length > 3 && (
          <span className="text-[10px] ink-muted">+{paper.tags.length - 3}</span>
        )}
      </div>

      <div className="flex items-center justify-between border-t subtle-border pt-3">
        <div className="flex items-center gap-2">
          <div className="flex h-6 w-6 items-center justify-center rounded-full bg-primary-500/15 text-[10px] font-bold text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
            {paper.createdByName?.charAt(0).toUpperCase()}
          </div>
          <span className="text-xs font-medium text-gray-700 dark:text-gray-200">{paper.createdByName}</span>
        </div>
        <span className="text-[10px] font-medium ink-muted">
          {formatDate(paper.createdAt)}
        </span>
      </div>
    </div>
  );
}

function CreatePaperModal({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: () => void;
}) {
  const [title, setTitle] = useState("");
  const [researchAbstract, setResearchAbstract] = useState("");
  const [category, setCategory] = useState<ResearchCategory>("PAPER");
  const [tags, setTags] = useState("");
  const [authors, setAuthors] = useState("");
  const [documentUrl, setDocumentUrl] = useState("");
  const [doi, setDoi] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !researchAbstract.trim()) return;
    try {
      setSubmitting(true);
      await researchService.create({
        title: title.trim(),
        researchAbstract: researchAbstract.trim(),
        category,
        tags: tags
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
        authors: authors
          .split(",")
          .map((a) => a.trim())
          .filter(Boolean),
        documentUrl: documentUrl.trim() || undefined,
        doi: doi.trim() || undefined,
      });
      onCreated();
    } catch {
      setError("Failed to publish paper");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="glass-panel w-full max-w-lg rounded-2xl p-6"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="mb-1 text-xl font-bold text-gray-900 dark:text-white">
          Publish Research Paper
        </h2>
        <p className="mb-6 text-sm ink-muted">Share your findings with the academic community.</p>
        
        {error && <div className="mb-4"><ErrorAlert message={error} onClose={() => setError("")} /></div>}
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="text"
            placeholder="Paper title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <textarea
            placeholder="Abstract..."
            value={researchAbstract}
            onChange={(e) => setResearchAbstract(e.target.value)}
            rows={4}
            required
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              placeholder="Authors (comma-separated)"
              value={authors}
              onChange={(e) => setAuthors(e.target.value)}
                className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value as ResearchCategory)}
              className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            >
              {CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c.replace(/_/g, " ")}
                </option>
              ))}
            </select>
          </div>
          <input
            type="text"
            placeholder="Tags (e.g. AI, Blockchain, Machine Learning)"
            value={tags}
            onChange={(e) => setTags(e.target.value)}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <input
            type="url"
            placeholder="Document URL (PDF link)"
            value={documentUrl}
            onChange={(e) => setDocumentUrl(e.target.value)}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <input
            type="text"
            placeholder="DOI (Digital Object Identifier)"
            value={doi}
            onChange={(e) => setDoi(e.target.value)}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <div className="flex justify-end gap-3 border-t subtle-border pt-4">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border subtle-border px-5 py-2 text-sm font-semibold ink-muted transition hover:bg-white/70 dark:hover:bg-white/10"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-6 py-2 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
            >
              {submitting ? "Publishing..." : "Publish Research"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function PaperDetailModal({
  paper,
  onClose,
  onCite,
  onUpdate,
}: {
  paper: ResearchResponse;
  onClose: () => void;
  onCite: () => void;
  onUpdate: () => void;
}) {
  const { user } = useAuth();
  const [tab, setTab] = useState<"overview" | "members">("overview");
  
  const isOwner = paper.createdBy === String(user?.id);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="glass-panel max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b subtle-border bg-white/85 px-6 py-4 backdrop-blur dark:bg-slate-900/70">
          <div className="flex gap-4">
            <button
              onClick={() => setTab("overview")}
              className={`text-sm font-bold transition ${tab === "overview" ? "text-primary-600" : "ink-muted hover:text-gray-700 dark:hover:text-gray-200"}`}
            >
              Overview
            </button>
            <button
              onClick={() => setTab("members")}
              className={`text-sm font-bold transition ${tab === "members" ? "text-primary-600" : "ink-muted hover:text-gray-700 dark:hover:text-gray-200"}`}
            >
              Team ({paper.members?.length || 0})
            </button>
          </div>
          <button
            onClick={onClose}
            className="rounded-full p-1 ink-muted hover:bg-white/70 hover:text-gray-700 dark:hover:bg-white/10 dark:hover:text-gray-200"
          >
            ✕
          </button>
        </div>

        <div className="p-8">
          {tab === "overview" ? (
            <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
              <div className="mb-4 flex items-center gap-3">
                <span className="inline-block rounded-full bg-primary-500/15 px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
                  {paper.category?.replace(/_/g, " ") || "GENERAL"}
                </span>
                <span className="text-xs font-medium ink-muted">
                  Published on {formatDate(paper.createdAt)}
                </span>
              </div>
              
              <h2 className="mb-3 text-2xl font-black leading-tight text-gray-900 dark:text-white">{paper.title}</h2>
              
              {paper.authors && paper.authors.length > 0 && (
                <p className="mb-6 text-sm font-medium ink-muted">
                  By <span className="text-gray-900 dark:text-white">{paper.authors.join(", ")}</span>
                </p>
              )}

              <div className="mb-8 rounded-2xl border subtle-border bg-white/60 p-6 dark:bg-white/5">
                <h3 className="mb-2 text-xs font-black uppercase tracking-widest ink-muted">Abstract</h3>
                <p className="whitespace-pre-line text-sm leading-relaxed text-gray-700 dark:text-gray-200">
                  {paper.researchAbstract}
                </p>
              </div>

              {paper.tags && paper.tags.length > 0 && (
                <div className="mb-8">
                  <h3 className="mb-3 text-xs font-black uppercase tracking-widest ink-muted">Research Focus</h3>
                  <div className="flex flex-wrap gap-2">
                    {paper.tags.map((tag: string) => (
                      <span
                        key={tag}
                        className="rounded-lg border subtle-border bg-white/70 px-3 py-1.5 text-xs font-bold ink-muted shadow-sm dark:bg-white/5"
                      >
                        #{tag}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              <div className="mb-8 flex items-center justify-around rounded-2xl border subtle-border bg-white/70 py-4 shadow-sm dark:bg-white/5">
                <div className="text-center">
                  <p className="text-lg font-black text-gray-900 dark:text-white">{paper.views}</p>
                  <p className="text-[10px] font-bold uppercase tracking-widest ink-muted">Views</p>
                </div>
                <div className="h-8 w-px subtle-border border-l"></div>
                <div className="text-center">
                  <p className="text-lg font-black text-gray-900 dark:text-white">{paper.downloads}</p>
                  <p className="text-[10px] font-bold uppercase tracking-widest ink-muted">Downloads</p>
                </div>
                <div className="h-8 w-px subtle-border border-l"></div>
                <div className="text-center">
                  <p className="text-lg font-black text-gray-900 dark:text-white">{paper.citations}</p>
                  <p className="text-[10px] font-bold uppercase tracking-widest ink-muted">Citations</p>
                </div>
              </div>

              <div className="flex items-center gap-4 border-t subtle-border pt-6">
                <button
                  onClick={onCite}
                  className="flex-1 rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 py-3 text-sm font-bold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110"
                >
                  Generate Citation
                </button>
                {paper.documentUrl && (
                  <a
                    href={paper.documentUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 rounded-xl border subtle-border bg-white/70 py-3 text-center text-sm font-bold text-gray-700 transition hover:bg-white dark:bg-white/5 dark:text-gray-200 dark:hover:bg-white/10"
                  >
                    Download Research
                  </a>
                )}
              </div>
            </div>
          ) : (
            <div className="animate-in fade-in slide-in-from-right-4 duration-300">
              <CollaborationManager paper={paper} isOwner={isOwner} onUpdate={onUpdate} />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function CollaborationManager({ 
  paper, 
  isOwner, 
  onUpdate 
}: { 
  paper: ResearchResponse; 
  isOwner: boolean; 
  onUpdate: () => void; 
}) {
  const [newUserId, setNewUserId] = useState("");
  const [newUserName, setNewUserName] = useState("");
  const [newRole, setNewRole] = useState<ProjectRole>("COLLABORATOR");
  const [adding, setAdding] = useState(false);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUserId || !newUserName) return;
    try {
      setAdding(true);
      await researchService.addMember(paper.id, {
        userId: parseInt(newUserId),
        userName: newUserName.trim(),
        role: newRole
      });
      setNewUserId("");
      setNewUserName("");
      onUpdate();
    } catch {
      alert("Failed to add member");
    } finally {
      setAdding(false);
    }
  };

  const handleRemove = async (userId: number) => {
    if (!window.confirm("Remove this collaborator?")) return;
    try {
      await researchService.removeMember(paper.id, userId);
      onUpdate();
    } catch {
      alert("Failed to remove member");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-black uppercase tracking-widest ink-muted">Research Team</h3>
        {isOwner && (
          <span className="rounded-full bg-primary-500/15 px-2.5 py-1 text-[10px] font-bold text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
            Project Owner
          </span>
        )}
      </div>

      <div className="grid gap-3">
        {paper.members?.map((member) => (
          <div 
            key={member.id} 
            className="flex items-center justify-between rounded-2xl border subtle-border bg-white/70 p-4 shadow-sm dark:bg-white/5"
          >
            <div className="flex items-center gap-3">
              <div className={`h-10 w-10 rounded-full flex items-center justify-center text-sm font-black ${
                member.role === 'OWNER' ? 'bg-primary-500/15 text-primary-700 dark:bg-primary-500/30 dark:text-primary-200' : 'bg-gray-200/60 text-gray-600 dark:bg-white/10 dark:text-gray-300'
              }`}>
                {member.userName.charAt(0).toUpperCase()}
              </div>
              <div>
                <p className="text-sm font-bold text-gray-900 dark:text-white">{member.userName}</p>
                <p className="text-[10px] font-bold uppercase tracking-widest ink-muted">{member.role}</p>
              </div>
            </div>
            {isOwner && member.role !== "OWNER" && (
              <button
                onClick={() => handleRemove(member.userId)}
                className="rounded-lg p-2 ink-muted transition hover:bg-red-50 hover:text-red-500"
              >
                ✕
              </button>
            )}
          </div>
        ))}
      </div>

      {isOwner && (
        <div className="mt-8 rounded-2xl border-2 border-dashed subtle-border bg-white/60 p-6 dark:bg-white/5">
          <h4 className="mb-4 text-xs font-black uppercase tracking-widest ink-muted">Add Team Member</h4>
          <form onSubmit={handleAdd} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <input
                type="number"
                placeholder="User ID"
                value={newUserId}
                onChange={(e) => setNewUserId(e.target.value)}
                required
                className="rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              />
              <input
                type="text"
                placeholder="User Name"
                value={newUserName}
                onChange={(e) => setNewUserName(e.target.value)}
                required
                className="rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              />
            </div>
            <select
              value={newRole}
              onChange={(e) => setNewRole(e.target.value as ProjectRole)}
              className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            >
              <option value="COLLABORATOR">Collaborator</option>
              <option value="VIEWER">Viewer</option>
            </select>
            <button
              type="submit"
              disabled={adding}
              className="w-full rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 py-2.5 text-sm font-bold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
            >
              {adding ? "Adding Member..." : "Add to Project"}
            </button>
          </form>
        </div>
      )}
    </div>
  );
}
