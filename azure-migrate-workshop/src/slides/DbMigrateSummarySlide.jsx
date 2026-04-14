import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DbMigrateSummarySlide.module.css'

export default function DbMigrateSummarySlide({ index, project }) {
  return (
    <Slide index={index} className={styles.dbMigrateSummary}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 34</p>
          <h2>Review &amp; <span className={styles.highlight}>Migrate</span></h2>
          <p className={styles.subtitle}>
            Verify the summary and start the migration
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Review the full migration summary — setup, runtime server, source and target server details are all listed for verification.</p>
              <p>When everything looks correct, click <strong>Start validation and migration</strong> to begin the process.</p>
              <p>The wizard will first validate the configuration and then start migrating the <strong>webapp</strong> database to Azure Database for PostgreSQL flexible server.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/dbmigrate-summary.png"
              alt="Migration summary and start"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
