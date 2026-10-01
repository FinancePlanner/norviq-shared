import Foundation

// MARK: - Enums

/// `link` posts carry a URL; `ask` and `show` are text posts surfaced by the
/// Ask/Show filters; `text` is a plain discussion post.
public enum BoardPostKind: String, Codable, CaseIterable, Sendable {
    case link
    case text
    case ask
    case show
}

/// `active` orders by most recent comment and backs the "Comments" tab.
public enum BoardPostSort: String, Codable, CaseIterable, Sendable {
    case new
    case top
    case active
}

/// Global, admin-issued. A mute leaves the boards readable; a ban hides them.
public enum CommunitySanctionKind: String, Codable, CaseIterable, Sendable {
    case mute
    case ban
}

/// Same values as the backend's social report reasons; board reports land in
/// the same review queue.
public enum BoardReportReason: String, Codable, CaseIterable, Sendable {
    case spam
    case harassment
    case hate
    case scam
    case impersonation
    case inappropriate
    case other
}

// MARK: - Boards

public struct BoardSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let slug: String
    public let name: String
    public let description: String
    /// Nil once the creator's account is gone.
    public let creatorUsername: String?
    public let postCount: Int
    public let createdAt: Date
    public let lastActivityAt: Date

    public init(
        id: UUID,
        slug: String,
        name: String,
        description: String,
        creatorUsername: String?,
        postCount: Int,
        createdAt: Date,
        lastActivityAt: Date
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.description = description
        self.creatorUsername = creatorUsername
        self.postCount = postCount
        self.createdAt = createdAt
        self.lastActivityAt = lastActivityAt
    }
}

public struct BoardListResponse: Codable, Sendable, Equatable {
    public let items: [BoardSummary]
    public let nextCursor: String?

    public init(items: [BoardSummary], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public struct CreateBoardRequest: Codable, Sendable, Equatable {
    public let slug: String
    public let name: String
    public let description: String

    public init(slug: String, name: String, description: String) {
        self.slug = slug
        self.name = name
        self.description = description
    }
}

/// Only the description is editable, and only by the creator.
public struct UpdateBoardRequest: Codable, Sendable, Equatable {
    public let description: String

    public init(description: String) {
        self.description = description
    }
}

// MARK: - Posts

public struct BoardPostSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let boardSlug: String
    public let kind: BoardPostKind
    public let title: String
    public let url: String?
    /// Host of `url` without a leading `www.`; nil for non-link posts.
    public let domain: String?
    public let tags: [String]
    public let authorUsername: String?
    public let createdAt: Date
    public let score: Int
    public let commentCount: Int
    public let participantCount: Int
    public let viewCount: Int
    public let viewerHasVoted: Bool
    /// Comments added since the viewer last opened the post; nil if never opened.
    public let newCommentCount: Int?

    public init(
        id: UUID,
        boardSlug: String,
        kind: BoardPostKind,
        title: String,
        url: String?,
        domain: String?,
        tags: [String],
        authorUsername: String?,
        createdAt: Date,
        score: Int,
        commentCount: Int,
        participantCount: Int,
        viewCount: Int,
        viewerHasVoted: Bool,
        newCommentCount: Int?
    ) {
        self.id = id
        self.boardSlug = boardSlug
        self.kind = kind
        self.title = title
        self.url = url
        self.domain = domain
        self.tags = tags
        self.authorUsername = authorUsername
        self.createdAt = createdAt
        self.score = score
        self.commentCount = commentCount
        self.participantCount = participantCount
        self.viewCount = viewCount
        self.viewerHasVoted = viewerHasVoted
        self.newCommentCount = newCommentCount
    }
}

public struct BoardPostPage: Codable, Sendable, Equatable {
    public let items: [BoardPostSummary]
    public let nextCursor: String?

    public init(items: [BoardPostSummary], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

/// Comments come back flat, ordered by creation; clients build the tree from
/// `parentId`. Deleted comments keep their slot with an empty body so replies
/// still have somewhere to hang.
public struct BoardComment: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let parentId: UUID?
    public let depth: Int
    public let authorUsername: String?
    public let body: String
    public let createdAt: Date
    public let isDeleted: Bool

    public init(
        id: UUID,
        parentId: UUID?,
        depth: Int,
        authorUsername: String?,
        body: String,
        createdAt: Date,
        isDeleted: Bool
    ) {
        self.id = id
        self.parentId = parentId
        self.depth = depth
        self.authorUsername = authorUsername
        self.body = body
        self.createdAt = createdAt
        self.isDeleted = isDeleted
    }
}

public struct BoardPostDetail: Codable, Sendable, Equatable {
    public let post: BoardPostSummary
    public let body: String?
    public let comments: [BoardComment]

    public init(post: BoardPostSummary, body: String?, comments: [BoardComment]) {
        self.post = post
        self.body = body
        self.comments = comments
    }
}

public struct CreateBoardPostRequest: Codable, Sendable, Equatable {
    public let kind: BoardPostKind
    public let title: String
    /// Required for `link`, rejected for the others.
    public let url: String?
    public let body: String?
    public let tags: [String]

    public init(kind: BoardPostKind, title: String, url: String?, body: String?, tags: [String]) {
        self.kind = kind
        self.title = title
        self.url = url
        self.body = body
        self.tags = tags
    }
}

public struct CreateBoardCommentRequest: Codable, Sendable, Equatable {
    public let parentId: UUID?
    public let body: String

    public init(parentId: UUID?, body: String) {
        self.parentId = parentId
        self.body = body
    }
}

public struct BoardVoteResponse: Codable, Sendable, Equatable {
    public let score: Int
    public let voted: Bool

    public init(score: Int, voted: Bool) {
        self.score = score
        self.voted = voted
    }
}

// MARK: - Reports and blocks

/// Exactly one of `postId` / `commentId` must be set.
public struct BoardReportRequest: Codable, Sendable, Equatable {
    public let postId: UUID?
    public let commentId: UUID?
    public let reason: BoardReportReason
    public let note: String?

    public init(postId: UUID?, commentId: UUID?, reason: BoardReportReason, note: String?) {
        self.postId = postId
        self.commentId = commentId
        self.reason = reason
        self.note = note
    }
}

public struct UserBlockRequest: Codable, Sendable, Equatable {
    public let username: String

    public init(username: String) {
        self.username = username
    }
}

// MARK: - Viewer and moderation

public struct UserSanction: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let username: String?
    public let kind: CommunitySanctionKind
    public let reason: String
    /// Nil means indefinite.
    public let expiresAt: Date?
    public let createdAt: Date
    public let revokedAt: Date?

    public init(
        id: UUID,
        username: String?,
        kind: CommunitySanctionKind,
        reason: String,
        expiresAt: Date?,
        createdAt: Date,
        revokedAt: Date?
    ) {
        self.id = id
        self.username = username
        self.kind = kind
        self.reason = reason
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.revokedAt = revokedAt
    }
}

/// What the client needs before rendering boards: whether to show admin
/// controls, and what stands between the viewer and posting.
public struct CommunityViewerStatus: Codable, Sendable, Equatable {
    /// The viewer's own username, so clients can tell their posts from others'.
    public let username: String?
    public let isAdmin: Bool
    public let guidelinesAccepted: Bool
    public let hasUsername: Bool
    public let activeSanction: UserSanction?

    public init(
        username: String?,
        isAdmin: Bool,
        guidelinesAccepted: Bool,
        hasUsername: Bool,
        activeSanction: UserSanction?
    ) {
        self.username = username
        self.isAdmin = isAdmin
        self.guidelinesAccepted = guidelinesAccepted
        self.hasUsername = hasUsername
        self.activeSanction = activeSanction
    }
}

public struct CreateSanctionRequest: Codable, Sendable, Equatable {
    public let username: String
    public let kind: CommunitySanctionKind
    public let reason: String
    /// Nil means indefinite.
    public let durationHours: Int?

    public init(username: String, kind: CommunitySanctionKind, reason: String, durationHours: Int?) {
        self.username = username
        self.kind = kind
        self.reason = reason
        self.durationHours = durationHours
    }
}

public struct UserSanctionListResponse: Codable, Sendable, Equatable {
    public let items: [UserSanction]

    public init(items: [UserSanction]) {
        self.items = items
    }
}

public struct BoardReportItem: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let reporterUsername: String?
    public let postId: UUID?
    public let commentId: UUID?
    public let boardSlug: String?
    /// Post title or comment body excerpt, so the queue is readable on its own.
    public let excerpt: String
    public let targetAuthorUsername: String?
    public let reason: BoardReportReason
    public let note: String?
    public let createdAt: Date

    public init(
        id: UUID,
        reporterUsername: String?,
        postId: UUID?,
        commentId: UUID?,
        boardSlug: String?,
        excerpt: String,
        targetAuthorUsername: String?,
        reason: BoardReportReason,
        note: String?,
        createdAt: Date
    ) {
        self.id = id
        self.reporterUsername = reporterUsername
        self.postId = postId
        self.commentId = commentId
        self.boardSlug = boardSlug
        self.excerpt = excerpt
        self.targetAuthorUsername = targetAuthorUsername
        self.reason = reason
        self.note = note
        self.createdAt = createdAt
    }
}

public struct BoardReportListResponse: Codable, Sendable, Equatable {
    public let items: [BoardReportItem]

    public init(items: [BoardReportItem]) {
        self.items = items
    }
}
