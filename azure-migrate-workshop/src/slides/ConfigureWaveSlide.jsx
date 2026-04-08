import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ConfigureWaveSlide.module.css'

export default function ConfigureWaveSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.configureWave}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 23</p>
          <h2>Configure <span className={styles.highlight}>Wave</span></h2>
          <p className={styles.subtitle}>
            Set up replication for the Hyper-V host
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>For a lift-and-shift migration, we need to set up <strong>replication</strong> for the Hyper-V host.</p>
              <p>Configure the wave settings to enable replication of the UbuntuVM to Azure.</p>
              <p><strong>Make sure to grant access to the MSI before taking any other steps.</strong></p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/ConfigureWave.png"
              alt="Configure Wave"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
