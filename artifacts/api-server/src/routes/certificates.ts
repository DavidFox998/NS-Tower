import { Router, type IRouter } from "express";
import { eq } from "drizzle-orm";
import { db, certificatesTable } from "@workspace/db";
import {
  GetCertificateParams,
  UpdateCertificateParams,
  UpdateCertificateBody,
} from "@workspace/api-zod";

const router: IRouter = Router();

const MASTER_SHA = "5b80b84d1d3d13e216eeecd8155c1edc854d578e7d2dae9c4bc72fcbf7ebe3c9";

router.get("/certificates/summary", async (req, res) => {
  try {
    const certs = await db.select().from(certificatesTable).orderBy(certificatesTable.dagPosition);
    const VERIFIED = new Set(["CERTIFIED", "LOCKED", "DISCHARGED"]);
    const certifiedCount = certs.filter((c) => VERIFIED.has(c.status)).length;
    const awaitingCount = certs.filter((c) => c.status === "AWAITING").length;
    const PDF_SLOT_PATTERN = /^M[1-9]$/i;
    const STATIC_PDF_PATTERN = /^M[1-8]$/i;
    const pdfSlotCerts = certs.filter((c) => PDF_SLOT_PATTERN.test(c.moduleId));
    const pdfUploadedCount = pdfSlotCerts.filter(
      (c) => c.pdfObjectPath !== null || STATIC_PDF_PATTERN.test(c.moduleId),
    ).length;
    const pdfTotal = pdfSlotCerts.length;
    const dagSealed =
      certs.length > 0 && certs.every((c) => VERIFIED.has(c.status));

    res.json({
      masterSha: MASTER_SHA,
      totalModules: certs.length,
      certifiedCount,
      awaitingCount,
      dagSealed,
      pdfUploadedCount,
      pdfTotal,
    });
  } catch (err) {
    req.log.error({ err }, "Failed to get summary");
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/certificates", async (req, res) => {
  try {
    const certs = await db.select().from(certificatesTable).orderBy(certificatesTable.dagPosition);
    res.json(
      certs.map((c) => ({
        ...c,
        parentShas: JSON.parse(c.parentShas),
      }))
    );
  } catch (err) {
    req.log.error({ err }, "Failed to list certificates");
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/certificates/:moduleId", async (req, res) => {
  const parsed = GetCertificateParams.safeParse(req.params);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid module ID" });
    return;
  }

  try {
    const [cert] = await db
      .select()
      .from(certificatesTable)
      .where(eq(certificatesTable.moduleId, parsed.data.moduleId));

    if (!cert) {
      res.status(404).json({ error: "Certificate not found" });
      return;
    }

    res.json({ ...cert, parentShas: JSON.parse(cert.parentShas) });
  } catch (err) {
    req.log.error({ err }, "Failed to get certificate");
    res.status(500).json({ error: "Internal server error" });
  }
});

router.patch("/certificates/:moduleId", async (req, res) => {
  const paramsParsed = UpdateCertificateParams.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({ error: "Invalid module ID" });
    return;
  }

  const bodyParsed = UpdateCertificateBody.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({ error: "Invalid body" });
    return;
  }

  try {
    const updates: Partial<typeof certificatesTable.$inferInsert> = {
      updatedAt: new Date(),
    };

    const { pdfObjectPath, notes, status } = bodyParsed.data;
    if (pdfObjectPath !== undefined) updates.pdfObjectPath = pdfObjectPath;
    if (notes !== undefined) updates.notes = notes;
    if (status !== undefined) updates.status = status;

    const [updated] = await db
      .update(certificatesTable)
      .set(updates)
      .where(eq(certificatesTable.moduleId, paramsParsed.data.moduleId))
      .returning();

    if (!updated) {
      res.status(404).json({ error: "Certificate not found" });
      return;
    }

    res.json({ ...updated, parentShas: JSON.parse(updated.parentShas) });
  } catch (err) {
    req.log.error({ err }, "Failed to update certificate");
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
