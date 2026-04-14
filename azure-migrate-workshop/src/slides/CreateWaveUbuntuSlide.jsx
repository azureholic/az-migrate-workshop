import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './CreateWaveUbuntuSlide.module.css'

export default function CreateWaveUbuntuSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.createWave}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 20</p>
          <h2>Create <span className={styles.highlight}>Wave</span> — Ubuntu</h2>
          <p className={styles.subtitle}>
            Group the UbuntuVM into a migration wave
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Create a migration <strong>wave</strong> for the UbuntuVM workload.</p>
              <p>Waves let you group workloads together and track their migration progress as a batch.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/CreateWave-Ubuntu.png"
              alt="Create Wave — Ubuntu"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
