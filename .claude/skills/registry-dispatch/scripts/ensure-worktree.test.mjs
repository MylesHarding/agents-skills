import { test } from "node:test";
import assert from "node:assert";
import { execSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const scriptPath = join(import.meta.dirname, "ensure-worktree.sh");

// Helper to create a minimal test git repo
function createTestRepo(path) {
  execSync(`git init --quiet --initial-branch=main "${path}"`);
  execSync(`git -C "${path}" config user.email "test@test.com"`);
  execSync(`git -C "${path}" config user.name "Test User"`);
  writeFileSync(join(path, "README.md"), "test repo\n");
  execSync(`git -C "${path}" add README.md`);
  execSync(`git -C "${path}" commit --quiet -m "initial"`);
}

test("ensure-worktree.sh with relative worktree_base creates single-nested worktree", async (t) => {
  const tempDir = mkdtempSync(join(tmpdir(), "ensure-worktree-test-"));
  try {
    // Create a test repo to clone from
    const sourceRepoPath = join(tempDir, "source-repo");
    createTestRepo(sourceRepoPath);

    // Test with a relative path
    const relativeBase = "test-repos/clone";
    const workingDir = tempDir;

    const result = spawnSync("bash", [scriptPath, relativeBase, sourceRepoPath, "main", "test-branch"], {
      cwd: workingDir,
      encoding: "utf8",
    });

    assert.equal(result.status, 0, `Script failed with: ${result.stderr}`);

    const worktreePath = result.stdout.trim();
    assert.ok(worktreePath, "Script should print worktree path to stdout");

    // Verify the path is NOT double-nested
    assert.match(worktreePath, /\.worktrees\/test-branch$/, "Worktree should end with .worktrees/test-branch");
    assert.ok(!worktreePath.match(/\/test-repos\/test-repos\//), "Worktree should not be double-nested");

    // Verify the worktree actually exists and is valid
    const checkResult = execSync(`git -C "${worktreePath}" rev-parse --git-dir`, { encoding: "utf8" });
    assert.ok(checkResult.includes(".git"), "Worktree should have a valid git directory");

    // Verify we can read the branch name
    const branchResult = execSync(`git -C "${worktreePath}" rev-parse --abbrev-ref HEAD`, { encoding: "utf8" });
    assert.equal(branchResult.trim(), "test-branch", "Branch should be checked out correctly");

    t.diagnostic(`✓ Single-nested worktree created at: ${worktreePath}`);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test("ensure-worktree.sh with absolute worktree_base creates single-nested worktree", async (t) => {
  const tempDir = mkdtempSync(join(tmpdir(), "ensure-worktree-test-"));
  try {
    // Create a test repo to clone from
    const sourceRepoPath = join(tempDir, "source-repo");
    createTestRepo(sourceRepoPath);

    // Test with an absolute path
    const absoluteBase = join(tempDir, "absolute-clone");
    const workingDir = tempDir;

    const result = spawnSync("bash", [scriptPath, absoluteBase, sourceRepoPath, "main", "test-branch"], {
      cwd: workingDir,
      encoding: "utf8",
    });

    assert.equal(result.status, 0, `Script failed with: ${result.stderr}`);

    const worktreePath = result.stdout.trim();
    assert.ok(worktreePath, "Script should print worktree path to stdout");

    // Verify the path is NOT double-nested
    assert.match(worktreePath, /\.worktrees\/test-branch$/, "Worktree should end with .worktrees/test-branch");
    assert.ok(!worktreePath.match(/\/absolute-clone\/absolute-clone\//), "Worktree should not be double-nested");

    // Verify the worktree actually exists and is valid
    const checkResult = execSync(`git -C "${worktreePath}" rev-parse --git-dir`, { encoding: "utf8" });
    assert.ok(checkResult.includes(".git"), "Worktree should have a valid git directory");

    t.diagnostic(`✓ Single-nested worktree created at: ${worktreePath}`);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test("ensure-worktree.sh re-run removes and recreates worktree cleanly", async (t) => {
  const tempDir = mkdtempSync(join(tmpdir(), "ensure-worktree-test-"));
  try {
    // Create a test repo to clone from
    const sourceRepoPath = join(tempDir, "source-repo");
    createTestRepo(sourceRepoPath);

    const relativeBase = "test-repos/clone";
    const workingDir = tempDir;
    const branchName = "test-branch";

    // First run
    const result1 = spawnSync("bash", [scriptPath, relativeBase, sourceRepoPath, "main", branchName], {
      cwd: workingDir,
      encoding: "utf8",
    });
    assert.equal(result1.status, 0, `First run failed with: ${result1.stderr}`);
    const worktreePath1 = result1.stdout.trim();

    // Create a marker file in the worktree
    const markerFile = join(worktreePath1, "marker.txt");
    writeFileSync(markerFile, "first-run\n");
    assert.ok(readFileSync(markerFile, "utf8"), "Marker file should exist after first run");

    // Second run (should clean up and recreate)
    const result2 = spawnSync("bash", [scriptPath, relativeBase, sourceRepoPath, "main", branchName], {
      cwd: workingDir,
      encoding: "utf8",
    });
    assert.equal(result2.status, 0, `Second run failed with: ${result2.stderr}`);
    const worktreePath2 = result2.stdout.trim();

    // Should be the same path
    assert.equal(worktreePath1, worktreePath2, "Worktree path should be the same on re-run");

    // Marker file should NOT exist (worktree was recreated)
    assert.throws(() => readFileSync(markerFile), "Marker file should not exist after worktree recreation");

    t.diagnostic(`✓ Worktree cleanup and recreation successful`);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test("ensure-worktree.sh checkout succeeds without double-nesting error", async (t) => {
  const tempDir = mkdtempSync(join(tmpdir(), "ensure-worktree-test-"));
  try {
    const sourceRepoPath = join(tempDir, "source-repo");
    createTestRepo(sourceRepoPath);

    const relativeBase = "test-repos/clone";
    const workingDir = tempDir;

    const result = spawnSync("bash", [scriptPath, relativeBase, sourceRepoPath, "main", "checkout-test"], {
      cwd: workingDir,
      encoding: "utf8",
    });

    // Main verification: script should not fail with "No such file or directory" on checkout
    assert.equal(result.status, 0, `Script failed with: ${result.stderr}`);
    assert.ok(!result.stderr.includes("No such file or directory"), "Should not have path resolution errors");

    t.diagnostic(`✓ Checkout succeeded without path resolution errors`);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});
