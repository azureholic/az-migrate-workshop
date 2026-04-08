import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ReplicationSlide.module.css'

export default function ReplicationSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.replication}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 28</p>
          <h2>Disk <span className={styles.highlight}>Replication</span></h2>
          <p className={styles.subtitle}>
            Wait for the Hyper-V disk replication to Azure
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Once the migration has started, the first step is that the Hyper-V disk(s) get <strong>replicated to Azure</strong>. From that disk an Azure VM will be created.</p>
              <p>This is a good time to grab a coffee and wait for the replication to finish. ☕</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/Replication.png"
              alt="Replication in progress"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
