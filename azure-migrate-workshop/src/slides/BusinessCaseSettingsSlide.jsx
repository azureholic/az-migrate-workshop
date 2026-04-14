import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './BusinessCaseSettingsSlide.module.css'

export default function BusinessCaseSettingsSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.businessCaseSettings}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 16</p>
          <h2>Business Case <span className={styles.highlight}>Settings</span></h2>
          <p className={styles.subtitle}>
            Configure the target settings and generate the business case
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Configure the business case settings to match your target environment.</p>
              <p>Review the options and click <strong>Build business case</strong> to generate the assessment.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/BusinessCaseSettings.png"
              alt="Business Case Settings"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
