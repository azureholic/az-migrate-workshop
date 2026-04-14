import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ServerCredentialsUbuntuSlide.module.css'

export default function ServerCredentialsUbuntuSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.serverCredentialsUbuntu}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 8</p>
          <h2>Server Credentials — <span className={styles.highlight}>Ubuntu</span></h2>
          <p className={styles.subtitle}>
            Provide server credentials to perform guest discovery of installed software, file shares, dependencies and workloads
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <h3 className={styles.sectionTitle}>Add Credentials</h3>

            <div className={styles.fieldGroup}>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Operating System</span>
                <span className={styles.fieldValue}>Linux</span>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Username</span>
                <code className={styles.fieldCode}>ubuntu</code>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Password</span>
                <code className={styles.fieldCode}>ubuntu</code>
              </div>
            </div>

            <p className={styles.hint}>
              Hit <strong>Add more</strong> to add the next set of credentials
            </p>
          </div>

          <div className={styles.right}>
            <img
              src="/Credentials-ubuntu.png"
              alt="Add credentials for Ubuntu server"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
